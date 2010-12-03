/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAJsonDataSource.h"
#import "OBACommon.h"
#import "OBALogger.h"
#import "SBJSON.h"


/****
 * Internal JsonUrlFetcher class that we pass on to our NSURLConnection
 ****/

@interface JsonUrlFetcherImpl : NSObject <OBADataSourceConnection> {
	OBAJsonDataSource * _source;
	NSURLConnection * _connection;
	NSStringEncoding _responseEncoding;
	NSMutableData * _jsonData;
	NSInteger _expectedLength;
	id<OBADataSourceDelegate> _delegate;
	id _context;
	BOOL _uploading;
	BOOL _canceled;
}

@property (nonatomic) BOOL uploading;

- (id) initWithSource:(OBAJsonDataSource*)source withDelegate:(id<OBADataSourceDelegate>)delegate context:(id)context;

@end

@interface OBAJsonDataSource (Private)

-(void) removeOpenConnection:(JsonUrlFetcherImpl*)connection;
-(NSString*) constructFormBody:(NSDictionary*)args;
-(NSString*) paramValueAsString:(id)value;
-(NSString*) escapeParamValue:(NSString*)v;

@end



@implementation OBAJsonDataSource

- (id) initWithConfig:(OBADataSourceConfig*)config {
	if( self = [super init] ) {
		_config = [config retain];
		_openConnections = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[self cancelOpenConnections];
	[_config release];
	[_openConnections release];
	[super dealloc];
}

- (id<OBADataSourceConnection>) requestWithPath:(NSString*)path withDelegate:(id<OBADataSourceDelegate>)delegate context:(id)context {
	return [self requestWithPath:path withArgs:nil withDelegate:delegate context: context];
}

- (id<OBADataSourceConnection>) requestWithPath:(NSString*)path withArgs:(NSString*)args withDelegate:(id<OBADataSourceDelegate>)delegate context:(id)context {
	
	NSURL *feedURL = [_config constructURL:path withArgs:args includeArgs:TRUE];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:feedURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval: 20];
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"]; 
	JsonUrlFetcherImpl * fetcher = [[JsonUrlFetcherImpl alloc] initWithSource:self withDelegate:delegate context:context];
	@synchronized(self) {
		[_openConnections addObject:fetcher];
		[NSURLConnection connectionWithRequest:request delegate:fetcher];
	}

	return fetcher;
}

- (id<OBADataSourceConnection>) postWithPath:(NSString*)url withArgs:(NSDictionary*)args withDelegate:(NSObject<OBADataSourceDelegate>*)delegate context:(id)context {
	
	NSURL *targetUrl = [_config constructURL:url withArgs:nil includeArgs:FALSE];
	NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:targetUrl];
	[postRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[postRequest setHTTPMethod:@"POST"];
	
	NSString * formBody = [self constructFormBody:args];
	[postRequest setHTTPBody:[formBody dataUsingEncoding:NSUTF8StringEncoding]];
	
	JsonUrlFetcherImpl * fetcher = [[JsonUrlFetcherImpl alloc] initWithSource:self withDelegate:delegate context:context];
	fetcher.uploading = TRUE;

	@synchronized(self) {
		[_openConnections addObject:fetcher];		
		[NSURLConnection connectionWithRequest:postRequest delegate:fetcher];
	}
	
	return fetcher;
}


- (id<OBADataSourceConnection>) requestWithPath:(NSString*)url withArgs:(NSString*)args withFileUpload:(NSString*)path withDelegate:(NSObject<OBADataSourceDelegate>*)delegate context:(id)context {

	NSURL *targetUrl = [_config constructURL:url withArgs:args includeArgs:TRUE];
	NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:targetUrl];
	//[postRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	//adding header information:
	[postRequest setHTTPMethod:@"POST"];
	
	NSString *stringBoundary = [NSString stringWithString:@"0xKhTmLbOuNdArY"];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
	[postRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
	
	//setting up the body:
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"upload\"; filename=\"upload\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	NSData * fileData = [NSData dataWithContentsOfFile:path];
	[postBody appendData:fileData];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postRequest setHTTPBody:postBody];
	
	JsonUrlFetcherImpl * fetcher = [[JsonUrlFetcherImpl alloc] initWithSource:self withDelegate:delegate context:context];
	fetcher.uploading = TRUE;
	@synchronized(self) {
		[_openConnections addObject:fetcher];		
		[NSURLConnection connectionWithRequest:postRequest delegate:fetcher];
	}
	
	return fetcher;
}

- (void) cancelOpenConnections {
	@synchronized(self) {
		for( JsonUrlFetcherImpl * connection in _openConnections )
			[connection cancel];
		[_openConnections removeAllObjects];
	}
}

@end

@implementation OBAJsonDataSource (Private)

-(void) removeOpenConnection:(JsonUrlFetcherImpl*)connection {
	@synchronized(self) {
		[_openConnections removeObject:connection];
	}
}

-(NSString*) constructFormBody:(NSDictionary*)args {
	NSMutableString * body = [NSMutableString string];
	if( _config.args )
		[body appendString:_config.args];
	for (NSString* paramName in args) {
		id values = [args objectForKey:paramName];
		if( ! [values isKindOfClass:[NSArray class]] )
			values = [NSArray arrayWithObject:values];
		
		for( id paramValue in values ) {
			if( [body length] > 0 )
				[body appendString:@"&"];
			[body appendString:paramName];
			[body appendString:@"="];
			NSString * stringValue = [self paramValueAsString:paramValue];
			stringValue = [self escapeParamValue:stringValue];
			[body appendString:stringValue];
		}
	}
	
	return body;
}
								   
-(NSString*) paramValueAsString:(id)value {
	if( [value isKindOfClass:[NSString class]] )
		return value;
	if( [value isKindOfClass:[NSNumber class]] )
		return [value stringValue];
	return [value description];
}

- (NSString *) escapeParamValue:(NSString *)s {
	NSString *reserved = @";/?:@&=+$,";
	return [NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)s, NULL, (CFStringRef)reserved, kCFStringEncodingUTF8)) autorelease];
}

@end




@implementation JsonUrlFetcherImpl

@synthesize uploading = _uploading;

- (id) initWithSource:(OBAJsonDataSource*)source withDelegate:(id<OBADataSourceDelegate>)delegate context:(id)context {

	if( self = [super init]) {
		
		_source = [source retain];
		_delegate = delegate;
		_context = [context retain];
		
		_jsonData = [[NSMutableData alloc] initWithCapacity:0];
		_uploading = FALSE;
		_canceled = FALSE;
		
	}
	return self;
}

- (void) dealloc {
	
	[_source release];
	[_context release];
	[_jsonData release];
	
	[super dealloc];
}

- (void) cancel {
	@synchronized(self) {
		if( _canceled )
			return;
		_canceled = TRUE;
		[_connection cancel];
		_delegate = nil;
		[self autorelease];
	}
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	@synchronized(self) {
		if( _canceled )
			return;
		if( _uploading && [((NSObject*)_delegate) respondsToSelector:@selector(connection:withProgress:)]) {
			float progress = ((float)totalBytesWritten)/totalBytesExpectedToWrite;
			[_delegate connection:self withProgress:progress];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	@synchronized(self) {
		if( _canceled )
			return;
		
		NSString * textEncodingName = [response textEncodingName];
		if( textEncodingName )
			_responseEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName));
		else
			_responseEncoding = NSUTF8StringEncoding;
		_expectedLength = [response expectedContentLength];
		[_jsonData setLength:0];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSMutableData *)data {
	@synchronized(self) {
		if( _canceled )
			return;
		[_jsonData appendData:data];
		if( [((NSObject*)_delegate) respondsToSelector:@selector(connection:withProgress:)] ) {
			float progress = [_jsonData length];
			if( _expectedLength > 0 )
				progress = ((float) [_jsonData length]) / _expectedLength;
			[_delegate connection:self withProgress:progress];
		}
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OBAApplicationDidCompleteNetworkRequestNotification object:self];
	
	@synchronized(self) {
		
		if( _canceled )
			return;
		_canceled = TRUE;
		
		NSString * v = [[NSString alloc] initWithData:_jsonData encoding:_responseEncoding];
		SBJSON * parser = [[SBJSON alloc] init];
		NSError * error = nil;
		id jsonObject = nil;

		if( v && [v length] > 0 )
			jsonObject = [parser objectWithString:v error:&error];
		
		if( error)
			[_delegate connectionDidFail:self withError:error context:_context];
		else
			[_delegate connectionDidFinishLoading:self withObject:jsonObject context:_context];
		
		[v release];
		[parser release];
		
		[_source removeOpenConnection:self];
		_delegate = nil;
		[self autorelease];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	@synchronized(self) {
		
		if( _canceled )
			return;
		_canceled = TRUE;
		
		[_delegate connectionDidFail:self withError:error context:_context];
		[_source removeOpenConnection:self];
		_delegate = nil;
		[self autorelease];
	}
}

@end

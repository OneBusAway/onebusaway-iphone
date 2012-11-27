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
#import "OBALogger.h"

/****
 * Internal JsonUrlFetcher class that we pass on to our NSURLConnection
 ****/

@interface JsonUrlFetcherImpl : NSObject <OBADataSourceConnection>
@property BOOL uploading;
- (id)initWithSource:(OBAJsonDataSource*)source withDelegate:(id<OBADataSourceDelegate>)delegate context:(id)context;
@end

@interface OBAJsonDataSource (Private)

-(void) removeOpenConnection:(JsonUrlFetcherImpl*)connection;
-(NSString*) constructFormBody:(NSDictionary*)args;
-(NSString*) paramValueAsString:(id)value;
-(NSString*) escapeParamValue:(NSString*)v;

@end

@interface OBAJsonDataSource ()
@property(strong) OBADataSourceConfig *config;
@property(strong) NSMutableArray *openConnections;
@end


@implementation OBAJsonDataSource

- (id) initWithConfig:(OBADataSourceConfig*)config {
    if( self = [super init] ) {
        self.config = config;
        self.openConnections = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc {
    [self cancelOpenConnections];
}

- (id<OBADataSourceConnection>) requestWithPath:(NSString*)path withDelegate:(id<OBADataSourceDelegate>)delegate context:(id)context {
    return [self requestWithPath:path withArgs:nil withDelegate:delegate context: context];
}

- (id<OBADataSourceConnection>) requestWithPath:(NSString*)path withArgs:(NSString*)args withDelegate:(id<OBADataSourceDelegate>)delegate context:(id)context {
    
    NSURL *feedURL = [_config constructURL:path withArgs:args includeArgs:YES];
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
    
    NSURL *targetUrl = [_config constructURL:url withArgs:nil includeArgs:NO];
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:targetUrl];
    [postRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [postRequest setHTTPMethod:@"POST"];
    
    NSString * formBody = [self constructFormBody:args];
    [postRequest setHTTPBody:[formBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    JsonUrlFetcherImpl * fetcher = [[JsonUrlFetcherImpl alloc] initWithSource:self withDelegate:delegate context:context];
    fetcher.uploading = YES;

    @synchronized(self) {
        [_openConnections addObject:fetcher];        
        [NSURLConnection connectionWithRequest:postRequest delegate:fetcher];
    }
    
    return fetcher;
}


- (id<OBADataSourceConnection>) requestWithPath:(NSString*)url withArgs:(NSString*)args withFileUpload:(NSString*)path withDelegate:(NSObject<OBADataSourceDelegate>*)delegate context:(id)context {

    NSURL *targetUrl = [_config constructURL:url withArgs:args includeArgs:YES];
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:targetUrl];
    //[postRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    //adding header information:
    [postRequest setHTTPMethod:@"POST"];
    
    NSString *stringBoundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
    [postRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    //setting up the body:
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"upload\"; filename=\"upload\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSData * fileData = [NSData dataWithContentsOfFile:path];
    [postBody appendData:fileData];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postRequest setHTTPBody:postBody];
    
    JsonUrlFetcherImpl * fetcher = [[JsonUrlFetcherImpl alloc] initWithSource:self withDelegate:delegate context:context];
    fetcher.uploading = YES;
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
        id values = args[paramName];
        if( ! [values isKindOfClass:[NSArray class]] )
            values = @[values];
        
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
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)s, NULL, (CFStringRef)reserved, kCFStringEncodingUTF8));
}

@end


@interface JsonUrlFetcherImpl ()
@property(strong) OBAJsonDataSource *source;
@property(strong) NSURLConnection *connection;
@property NSStringEncoding responseEncoding;
@property(strong) NSMutableData *jsonData;
@property NSInteger expectedLength;
@property(weak) id<OBADataSourceDelegate> delegate;
@property(strong) id context;
@property BOOL canceled;
@end

@implementation JsonUrlFetcherImpl

@synthesize uploading = _uploading;

- (id) initWithSource:(OBAJsonDataSource*)source withDelegate:(id<OBADataSourceDelegate>)delegate context:(id)context {

    self = [super init];

    if (self) {
        self.source = source;
        self.delegate = delegate;
        self.context = context;
        
        self.jsonData = [[NSMutableData alloc] initWithCapacity:0];
        self.uploading = NO;
        self.canceled = NO;
        
    }
    return self;
}

- (void)cancel {
    @synchronized(self) {
        if (self.canceled) {
            return;
        }
            
        self.canceled = YES;
        [self.connection cancel];
        self.delegate = nil;
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
        
        if (self.canceled)
        {
            return;
        }
        
        self.canceled = YES;

        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:self.jsonData options:0 error:&error];

        if (error)
        {
            [self.delegate connectionDidFail:self withError:error context:self.context];
        }
        else
        {
            [self.delegate connectionDidFinishLoading:self withObject:jsonObject context:self.context];
        }
                
        [_source removeOpenConnection:self];
        self.delegate = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    @synchronized(self) {
        
        if (self.canceled) {
            return;
        }
            
        self.canceled = YES;
        
        [self.delegate connectionDidFail:self withError:error context:self.context];
        [self.source removeOpenConnection:self];
        self.delegate = nil;
    }
}

@end

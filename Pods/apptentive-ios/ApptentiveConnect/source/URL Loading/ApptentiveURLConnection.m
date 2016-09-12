//
//  ApptentiveURLConnection.m
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveURLConnection.h"
#import "ApptentiveURLConnection_Private.h"
#import "ApptentiveUtilities.h"


@interface ApptentiveURLConnection ()

@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) NSMutableDictionary *headers;
@property (strong, nonatomic) NSInputStream *HTTPBodyStream;
@property (strong, nonatomic) NSMutableURLRequest *request;
@property (copy, nonatomic) NSString *statusLine;
@property (copy, nonatomic) NSDictionary *responseHeaders;
@property (readwrite, assign, nonatomic) NSInteger statusCode;
@property (readwrite, assign, nonatomic) NSTimeInterval expiresMaxAge;
@property (readwrite, assign, nonatomic) BOOL failedAuthentication;
@property (readwrite, assign, nonatomic) BOOL cancelled;

@end


@implementation ApptentiveURLConnection

- (id)initWithURL:(NSURL *)url {
	return [self initWithURL:url delegate:nil];
}

- (id)initWithURL:(NSURL *)url delegate:(id)aDelegate {
	if ((self = [super init])) {
		_targetURL = [url copy];
		_delegate = aDelegate;
		_data = [[NSMutableData alloc] init];
		_finished = NO;
		_executing = NO;
		_failed = NO;
		_failedAuthentication = NO;
		_timeoutInterval = 10.0;

		_headers = [[NSMutableDictionary alloc] init];
		_HTTPMethod = nil;

		_statusCode = 0;
		_percentComplete = 0.0f;
		return self;
	}
	return nil;
}

- (BOOL)isExecuting {
	return self.executing;
}

- (BOOL)isFinished {
	return self.finished;
}

- (BOOL)isCancelled {
	return self.cancelled;
}

- (NSDictionary *)headers {
	return _headers;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
	[_headers setValue:value forKey:field];
}

- (void)removeHTTPHeaderField:(NSString *)field {
	if ([_headers objectForKey:field]) {
		[_headers removeObjectForKey:field];
	}
}

- (void)start {
	@synchronized(self) {
		@autoreleasepool {
			do { // once
				if ([self isCancelled]) {
					self.finished = YES;
					break;
				}
				if ([self isFinished]) {
					break;
				}
				self.request = [[NSMutableURLRequest alloc] initWithURL:self.targetURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:self.timeoutInterval];
				for (NSString *key in self.headers) {
					[self.request setValue:[self.headers objectForKey:key] forHTTPHeaderField:key];
				}
				if (self.HTTPMethod) {
					[self.request setHTTPMethod:self.HTTPMethod];
				}
				if (self.HTTPBody) {
					[self.request setHTTPBody:self.HTTPBody];
				} else if (self.HTTPBodyStream) {
					[self.request setHTTPBodyStream:self.HTTPBodyStream];
				}
				self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
				[self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
				[self.connection start];
				self.executing = YES;
			} while (NO);
		}
	}
}


- (NSData *)responseData {
	return self.data;
}

#pragma mark Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	@synchronized(self) {
		[self.data setLength:0];
		if (response) {
			if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
				self.statusLine = [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode];
				self.statusCode = response.statusCode;
			} else {
				self.statusCode = 200;
			}

			self.responseHeaders = [[response allHeaderFields] copy];
			NSString *cacheControlHeader = [self.responseHeaders valueForKey:@"Cache-Control"];
			if (cacheControlHeader) {
				self.expiresMaxAge = [ApptentiveUtilities maxAgeFromCacheControlHeader:cacheControlHeader];
			} else {
				self.expiresMaxAge = 0;
			}
		}
	}
}
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	@synchronized(self) {
		self.failed = YES;
		self.finished = YES;
		self.executing = NO;
		if (error) {
			self.connectionError = error;
		}
		if (self.delegate && [self.delegate respondsToSelector:@selector(connectionFailed:)]) {
			[self.delegate performSelectorOnMainThread:@selector(connectionFailed:) withObject:self waitUntilDone:YES];
		} else {
			ApptentiveLogError(@"Orphaned connection. No delegate or nonresponsive delegate.");
		}
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)someData {
	@synchronized(self) {
		[self.data appendData:someData];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	@synchronized(self) {
		if (self.data && !self.failed) {
			if (self.delegate != nil && ![self isCancelled]) {
				self.percentComplete = 1.0f;
				[self cacheDataIfNeeded];
				if (self.delegate && [self.delegate respondsToSelector:@selector(connectionFinishedSuccessfully:)]) {
					[self.delegate performSelectorOnMainThread:@selector(connectionFinishedSuccessfully:) withObject:self waitUntilDone:YES];
				} else {
					ApptentiveLogError(@"Orphaned connection. No delegate or nonresponsive delegate.");
				}
			}
			self.data = nil;
		} else if (self.delegate && ![self isCancelled]) {
			if (self.delegate && [self.delegate respondsToSelector:@selector(connectionFailed:)]) {
				[self.delegate performSelectorOnMainThread:@selector(connectionFailed:) withObject:self waitUntilDone:YES];
			} else {
				ApptentiveLogError(@"Orphaned connection. No delegate or nonresponsive delegate.");
			}
		}
		self.executing = NO;
		self.finished = YES;
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	@synchronized(self) {
		if (self.credential && [challenge previousFailureCount] == 0) {
			[[challenge sender] useCredential:self.credential forAuthenticationChallenge:challenge];
		} else {
			self.failedAuthentication = YES;
			[[challenge sender] cancelAuthenticationChallenge:challenge];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	@synchronized(self) {
		self.failed = YES;
		self.finished = YES;
		self.executing = NO;
		self.failedAuthentication = YES;
		if (self.delegate && [self.delegate respondsToSelector:@selector(connectionFailed:)]) {
			[self.delegate performSelectorOnMainThread:@selector(connectionFailed:) withObject:self waitUntilDone:YES];
		} else {
			ApptentiveLogError(@"Orphaned connection. No delegate or nonresponsive delegate.");
		}
	}
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	if (self.delegate && [self.delegate respondsToSelector:@selector(connectionDidProgress:)]) {
		self.percentComplete = ((float)totalBytesWritten) / ((float)totalBytesExpectedToWrite);
		[self.delegate performSelectorOnMainThread:@selector(connectionDidProgress:) withObject:self waitUntilDone:YES];
	} else {
		ApptentiveLogError(@"Orphaned connection. No delegate or nonresponsive delegate.");
	}
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)aConnection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	// See: http://blackpixel.com/blog/1659/caching-and-nsurlconnection/
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)[cachedResponse response];
	NSURLRequest *r = nil;
	if ([aConnection respondsToSelector:@selector(currentRequest)]) {
		r = [aConnection currentRequest];
	}
	if (r != nil && [r cachePolicy] == NSURLRequestUseProtocolCachePolicy) {
		self.responseHeaders = [httpResponse allHeaderFields];
		NSString *cacheControlHeader = [self.responseHeaders valueForKey:@"Cache-Control"];
		NSString *expiresHeader = [self.responseHeaders valueForKey:@"Expires"];
		if ((cacheControlHeader == nil) && (expiresHeader == nil)) {
			return nil;
		}
	}
	return cachedResponse;
}

- (NSURLRequest *)connection:(NSURLConnection *)inConnection willSendRequest:(NSURLRequest *)inRequest redirectResponse:(NSURLResponse *)inRedirectResponse {
	if (inRedirectResponse) {
		NSMutableURLRequest *r = [self.request mutableCopy];
		[r setURL:[inRequest URL]];
		return r;
	} else {
		return inRequest;
	}
}

- (void)setExecuting:(BOOL)isExecuting {
	[self willChangeValueForKey:@"isExecuting"];
	_executing = isExecuting;
	[self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)isFinished {
	[self willChangeValueForKey:@"isFinished"];
	_finished = isFinished;
	[self didChangeValueForKey:@"isFinished"];
}

- (void)cacheDataIfNeeded {
}

- (NSString *)requestAsString {
	NSMutableString *result = [NSMutableString string];
	[result appendFormat:@"%@ %@\n", self.HTTPMethod ? self.HTTPMethod : @"GET", [self.targetURL absoluteURL]];
	for (NSString *key in self.headers) {
		NSString *value = [self.headers valueForKey:key];
		[result appendFormat:@"%@: %@\n", key, value];
	}
	[result appendString:@"\n\n"];
	if (self.HTTPBody) {
		NSString *a = [[NSString alloc] initWithData:self.HTTPBody encoding:NSUTF8StringEncoding];
		if (a) {
			[result appendString:a];
		} else {
			[result appendFormat:@"<Data of length:%ld>", (long)[self.HTTPBody length]];
		}
	} else if (self.HTTPBodyStream) {
		[result appendString:@"<NSInputStream>"];
	}
	return result;
}

- (NSString *)responseAsString {
	NSMutableString *result = [NSMutableString string];
	[result appendFormat:@"%ld %@\n", (long)[self statusCode], [self statusLine]];
	NSDictionary *allHeaders = [self responseHeaders];
	for (NSString *key in allHeaders) {
		[result appendFormat:@"%@: %@\n", key, allHeaders[key]];
	}
	[result appendString:@"\n\n"];
	NSString *responseString = [[NSString alloc] initWithData:[self responseData] encoding:NSUTF8StringEncoding];
	if (responseString != nil) {
		[result appendString:responseString];
	} else {
		[result appendString:@"<NO RESPONSE BODY>"];
	}
	responseString = nil;
	return result;
}

#pragma mark - Private methods

- (void)cancel {
	@synchronized(self) {
		if (self.finished) {
			return;
		}
		self.delegate = nil;
		if (self.connection) {
			[self.connection cancel];
		}
		self.executing = NO;
		self.cancelled = YES;
	}
}
@end

//
//  JsonUrlFetcherImpl.m
//  OneBusAwaySDK
//
//  Created by Aaron Brethorst on 12/16/15.
//  Copyright © 2015 One Bus Away. All rights reserved.
//

#import "JsonUrlFetcherImpl.h"

@interface JsonUrlFetcherImpl () 


@end


@implementation JsonUrlFetcherImpl

- (void)loadRequest:(NSURLRequest *)request {
    static NSOperationQueue *connectionQueue;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        connectionQueue = [[NSOperationQueue alloc] init];
    });

    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:connectionQueue];
    [self.connection start];
}

- (NSMutableData *)responseData {
    if (!_responseData) {
        _responseData = [[NSMutableData alloc] init];
    }

    return _responseData;
}

- (void)cancel {
    [self.connection cancel];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (self.uploading) {
        float progress = ((float)totalBytesWritten) / totalBytesExpectedToWrite;

        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.progressBlock) {
                self.progressBlock(progress);
            }
        });
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.requestResponse = (NSHTTPURLResponse *)response;

    NSString *textEncodingName = [response textEncodingName];

    if (textEncodingName) {
        self.responseEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName));
    }
    else {
        self.responseEncoding = NSUTF8StringEncoding;
    }

    self.expectedLength = (NSInteger)response.expectedContentLength;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSMutableData *)data {
    [self.responseData appendData:data];

    if (self.progressBlock) {
        float progress = [self.responseData length];

        if (self.expectedLength > 0) {
            progress = ((float)[self.responseData length]) / self.expectedLength;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.progressBlock) {
                self.progressBlock(progress);
            }
        });
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError *error = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
    id jsonObject = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&error];
#pragma clang diagnostic pop
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completionBlock) {
            self.completionBlock(jsonObject, self.requestResponse.statusCode, error);
        }
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completionBlock) {
            self.completionBlock(nil, NSUIntegerMax, error);
        }
    });
}

@end

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
#import "JsonUrlFetcherImpl.h"

@interface OBAJsonDataSource ()

@property (strong) OBADataSourceConfig *config;
@property (strong) NSHashTable *openConnections;
@end


@implementation OBAJsonDataSource

- (id)initWithConfig:(OBADataSourceConfig *)config {
    if (self = [super init]) {
        self.config = config;
        self.openConnections = [NSHashTable weakObjectsHashTable];
    }

    return self;
}

- (void)dealloc {
    [self cancelOpenConnections];
}

- (id<OBADataSourceConnection>)requestWithPath:(NSString *)path completionBlock:(OBADataSourceCompletion)completion {
    return [self requestWithPath:path withArgs:nil completionBlock:completion progressBlock:nil];
}

- (id<OBADataSourceConnection>)requestWithPath:(NSString *)path withArgs:(NSString *)args completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    NSURL *feedURL = [self.config constructURL:path withArgs:args includeArgs:YES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:feedURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];

    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    JsonUrlFetcherImpl *fetcher = [[JsonUrlFetcherImpl alloc] init];
    fetcher.completionBlock = completion;
    fetcher.progressBlock = progress;
    [self.openConnections addObject:fetcher];
    [fetcher loadRequest:request];

    return fetcher;
}

- (id<OBADataSourceConnection>)postWithPath:(NSString *)url withArgs:(NSDictionary *)args completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    NSURL *targetUrl = [_config constructURL:url withArgs:nil includeArgs:NO];
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:targetUrl];

    [postRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [postRequest setHTTPMethod:@"POST"];

    NSString *formBody = [self constructFormBody:args];
    [postRequest setHTTPBody:[formBody dataUsingEncoding:NSUTF8StringEncoding]];

    JsonUrlFetcherImpl *fetcher = [[JsonUrlFetcherImpl alloc] init];
    fetcher.progressBlock = progress;
    fetcher.completionBlock = completion;
    fetcher.uploading = YES;

    [self.openConnections addObject:fetcher];
    [fetcher loadRequest:postRequest];

    return fetcher;
}

- (id<OBADataSourceConnection>)requestWithPath:(NSString *)url withArgs:(NSString *)args withFileUpload:(NSString *)path completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    NSURL *targetUrl = [_config constructURL:url withArgs:args includeArgs:YES];
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:targetUrl];

    //adding header information:
    [postRequest setHTTPMethod:@"POST"];

    NSString *stringBoundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
    [postRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];

    //setting up the body:
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"upload\"; filename=\"upload\"\r\n" dataUsingEncoding : NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding : NSUTF8StringEncoding]];
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    [postBody appendData:fileData];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postRequest setHTTPBody:postBody];

    JsonUrlFetcherImpl *fetcher = [[JsonUrlFetcherImpl alloc] init];

    fetcher.progressBlock = progress;
    fetcher.completionBlock = completion;
    fetcher.uploading = YES;

    [self.openConnections addObject:fetcher];
    [fetcher loadRequest:postRequest];

    return fetcher;
}

- (void)cancelOpenConnections {
    for (JsonUrlFetcherImpl *fetcher in self.openConnections) {
        [fetcher cancel];
    }

    [self.openConnections removeAllObjects];
}

- (NSString *)constructFormBody:(NSDictionary *)args {
    NSMutableString *body = [NSMutableString string];

    if (_config.args) [body appendString:_config.args];

    for (NSString *paramName in args) {
        id values = args[paramName];

        if (![values isKindOfClass:[NSArray class]]) values = @[values];

        for (id paramValue in values) {
            if ([body length] > 0) [body appendString:@"&"];

            [body appendString:paramName];
            [body appendString:@"="];
            NSString *stringValue = [self paramValueAsString:paramValue];
            stringValue = [self escapeParamValue:stringValue];
            [body appendString:stringValue];
        }
    }

    return body;
}

- (NSString *)paramValueAsString:(id)value {
    if ([value isKindOfClass:[NSString class]]) return value;

    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];

    return [value description];
}

- (NSString *)escapeParamValue:(NSString *)s {
    NSString *reserved = @";/?:@&=+$,";

    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)s, NULL, (CFStringRef)reserved, kCFStringEncodingUTF8));
}

@end

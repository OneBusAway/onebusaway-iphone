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

#import <OBAKit/OBAJsonDataSource.h>
#import <OBAKit/JsonUrlFetcherImpl.h>
#import <OBAKit/OBACommon.h>
#import <OBAKit/NSDictionary+OBAAdditions.h>
#import <OBAKit/NSObject+OBADescription.h>

@interface OBAJsonDataSource ()
@property(nonatomic,strong) NSHashTable *openConnections;
@end

@implementation OBAJsonDataSource

- (id)initWithConfig:(OBADataSourceConfig *)config {
    if (self = [super init]) {
        _config = config;
        _openConnections = [NSHashTable weakObjectsHashTable];
    }

    return self;
}

- (void)dealloc {
    [self cancelOpenConnections];
}

#pragma mark - Factory Helpers

+ (instancetype)JSONDataSourceWithBaseURL:(NSURL*)URL userID:(NSString*)userID {
    OBADataSourceConfig *obaDataSourceConfig = [OBADataSourceConfig dataSourceConfigWithBaseURL:URL userID:userID];
    return [[OBAJsonDataSource alloc] initWithConfig:obaDataSourceConfig];
}

+ (instancetype)googleMapsJSONDataSource {
    OBADataSourceConfig *googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithURL:[NSURL URLWithString:@"https://maps.googleapis.com"] args:@{@"sensor": @"true"}];
    return [[OBAJsonDataSource alloc] initWithConfig:googleMapsDataSourceConfig];
}

+ (instancetype)obacoJSONDataSource {
    OBADataSourceConfig *obacoConfig = [[OBADataSourceConfig alloc] initWithURL:[NSURL URLWithString:OBADeepLinkServerAddress] args:nil];
    return [[OBAJsonDataSource alloc] initWithConfig:obacoConfig];
}

#pragma mark - Public Methods

- (NSMutableURLRequest*)requestWithURL:(NSURL*)URL HTTPMethod:(NSString*)HTTPMethod {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    request.HTTPMethod = HTTPMethod;

    return request;
}

- (id<OBADataSourceConnection>)performRequest:(NSURLRequest*)request completionBlock:(OBADataSourceCompletion) completion {
    JsonUrlFetcherImpl *fetcher = [[JsonUrlFetcherImpl alloc] initWithCompletionBlock:completion];
    [self.openConnections addObject:fetcher];
    [fetcher loadRequest:request];

    return fetcher;
}

- (id<OBADataSourceConnection>)requestWithPath:(NSString*)path
                                    HTTPMethod:(NSString*)httpMethod
                               queryParameters:(nullable NSDictionary*)queryParameters
                                      formBody:(nullable NSDictionary*)formBody
                               completionBlock:(OBADataSourceCompletion) completion {

    NSMutableURLRequest *request = [self requestWithURL:[self.config constructURL:path withArgs:queryParameters] HTTPMethod:httpMethod];

    if (formBody && [self.class requestSupportsHTTPBody:request]) {
        request.HTTPBody = [formBody oba_toHTTPBodyData];
    }

    return [self performRequest:request completionBlock:completion];
}

- (void)cancelOpenConnections {
    for (JsonUrlFetcherImpl *fetcher in self.openConnections) {
        [fetcher cancel];
    }

    [self.openConnections removeAllObjects];
}

+ (BOOL)requestSupportsHTTPBody:(NSURLRequest*)request {
    return [@[@"post", @"patch", @"put"] containsObject:request.HTTPMethod.lowercaseString];
}

- (NSString*)description {
    return [self oba_description:@[] keyPaths:@[@"config"]];
}

@end

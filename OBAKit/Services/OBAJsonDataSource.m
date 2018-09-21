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
#import <OBAKit/OBACommon.h>
#import <OBAKit/NSDictionary+OBAAdditions.h>
#import <OBAKit/NSObject+OBADescription.h>
#import <OBAKit/OBAKit-Swift.h>

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

- (NSURLSession*)URLSession {
    if (!_URLSession) {
        _URLSession = [NSURLSession sharedSession];
    }
    return _URLSession;
}

#pragma mark - Factory Helpers

+ (instancetype)JSONDataSourceWithBaseURL:(NSURL*)URL userID:(NSString*)userID {
    OBADataSourceConfig *config = [[OBADataSourceConfig alloc] initWithBaseURL:URL userID:userID checkStatusCodeInBody:YES];
    OBAJsonDataSource *dataSource = [[OBAJsonDataSource alloc] initWithConfig:config];

    return dataSource;
}

+ (instancetype)unparsedDataSourceWithBaseURL:(NSURL*)URL userID:(NSString*)userID {
    OBADataSourceConfig *config = [[OBADataSourceConfig alloc] initWithBaseURL:URL userID:userID checkStatusCodeInBody:NO];
    config.contentType = OBADataSourceContentTypeRaw;
    return [[OBAJsonDataSource alloc] initWithConfig:config];
}

+ (instancetype)obacoJSONDataSource {
    OBADataSourceConfig *config = [[OBADataSourceConfig alloc] initWithBaseURL:[NSURL URLWithString:OBADeepLinkServerAddress] userID:nil checkStatusCodeInBody:NO];
    return [[OBAJsonDataSource alloc] initWithConfig:config];
}

#pragma mark - Public Methods

- (NSURL*)constructURLFromPath:(NSString*)path params:(nullable NSDictionary*)params {
    return [self.config constructURL:path withArgs:params];
}

- (OBAURLRequest*)buildGETRequestWithPath:(NSString*)path queryParameters:(nullable NSDictionary*)queryParameters {
    return [self buildRequestWithPath:path HTTPMethod:@"GET" queryParameters:queryParameters formBody:nil];
}

- (OBAURLRequest*)buildRequestWithPath:(NSString*)path HTTPMethod:(NSString*)httpMethod queryParameters:(nullable NSDictionary*)queryParameters formBody:(nullable NSDictionary*)formBody {
    return [self buildRequestWithURL:[self constructURLFromPath:path params:queryParameters] HTTPMethod:httpMethod formBody:formBody];
}

- (OBAURLRequest*)buildRequestWithURL:(NSURL*)URL HTTPMethod:(NSString*)httpMethod formBody:(nullable NSDictionary*)formBody {
    OBAURLRequest *request = [OBAURLRequest requestWithURL:URL httpMethod:httpMethod checkStatusCodeInBody:self.checkStatusCodeInBody];

    BOOL requestSupportsHTTPBody = [@[@"post", @"patch", @"put"] containsObject:httpMethod.lowercaseString];
    if (formBody && requestSupportsHTTPBody) {
        request.HTTPBody = [formBody oba_toHTTPBodyData];
    }

    return request;
}

- (NSURLSessionTask*)requestWithPath:(NSString*)path
                          HTTPMethod:(NSString*)httpMethod
                     queryParameters:(nullable NSDictionary*)queryParameters
                            formBody:(nullable NSDictionary*)formBody
                     completionBlock:(OBADataSourceCompletion)completion {

    OBAURLRequest *request = [self buildRequestWithPath:path
                                            HTTPMethod:httpMethod
                                       queryParameters:queryParameters
                                              formBody:formBody];

    return [self performRequest:request completionBlock:completion];
}

- (NSURLSessionTask*)createURLSessionTask:(NSURLRequest*)request completion:(nullable OBADataSourceCompletion)completion {
    NSURLSessionDataTask *task = [self.URLSession dataTaskWithRequest:request
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        id responseObject = nil;

        if (data.length) {
            NSError *jsonError = nil;
            responseObject = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&jsonError];

            if (!responseObject && jsonError) {
                error = jsonError;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(responseObject, (NSHTTPURLResponse*)response, error);
            }
        });
    }];

    [self.openConnections addObject:task];

    return task;
}

- (NSURLSessionTask*)performRequest:(NSURLRequest*)request completionBlock:(nullable OBADataSourceCompletion)completion {
    NSURLSessionTask *task = [self createURLSessionTask:request completion:completion];
    [task resume];

    return task;
}

- (void)cancelOpenConnections {
    for (NSURLSessionTask *task in self.openConnections) {
        [task cancel];
    }

    [self.openConnections removeAllObjects];
}

- (NSString*)description {
    return [self oba_description:@[] keyPaths:@[@"config"]];
}

- (BOOL)checkStatusCodeInBody {
    return self.config.checkStatusCodeInBody;
}

@end

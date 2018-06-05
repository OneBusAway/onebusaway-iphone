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

@import Foundation;
#import <OBAKit/OBADataSourceConfig.h>
#import <OBAKit/OBAModelServiceRequest.h>

@class OBAURLRequest;

NS_ASSUME_NONNULL_BEGIN

@interface OBAJsonDataSource : NSObject
@property(nonatomic,strong) OBADataSourceConfig *config;
@property(nonatomic,strong) NSURLSession *URLSession;
@property(nonatomic,assign,readonly) BOOL checkStatusCodeInBody;

+ (instancetype)JSONDataSourceWithBaseURL:(NSURL*)URL userID:(NSString*)userID;

/**
 OBA.co, obaco, or onebusaway.co is the service that powers deep links in the app,
 along with other cross-regional services.
 */
+ (instancetype)obacoJSONDataSource;

- (instancetype)initWithConfig:(OBADataSourceConfig*)config checkStatusCodeInBody:(BOOL)checkStatusCodeInBody;

/**
 Creates an URL request based upon the supplied path and HTTP method, configuring other parameters, like a GZIP header.

 @param path The URL path to load. The full URL will be constructed from the config object passed in at init-time.
 @param queryParameters An optional list of query parameters to append to the URL. Turned into: `?key1=value&key2=value`.
 @return An URLRequest suitable for loading data.
 */
- (OBAURLRequest*)buildGETRequestWithPath:(NSString*)path queryParameters:(nullable NSDictionary*)queryParameters;

/**
 Creates an URL request based upon the supplied path and HTTP method, configuring other parameters, like a GZIP header.

 @param path The URL path to load. The full URL will be constructed from the config object passed in at init-time.
 @param httpMethod GET, POST, PUT, PATCH, DELETE.
 @param queryParameters An optional list of query parameters to append to the URL. Turned into: `?key1=value&key2=value`.
 @param formBody Optional form body contents.
 @return An URLRequest suitable for loading data.
 */
- (OBAURLRequest*)buildRequestWithPath:(NSString*)path HTTPMethod:(NSString*)httpMethod queryParameters:(nullable NSDictionary*)queryParameters formBody:(nullable NSDictionary*)formBody;

/**
 Creates an URL request based upon the supplied URL and HTTP method, configuring other parameters, like a GZIP header.

 @param URL The URL to load.
 @param httpMethod GET, POST, PUT, PATCH, DELETE.
 @param formBody Optional form body contents.
 @return An URLRequest suitable for loading data.
 */
- (OBAURLRequest*)buildRequestWithURL:(NSURL*)URL HTTPMethod:(NSString*)httpMethod formBody:(nullable NSDictionary*)formBody;

/**
 Creates an NSURLSessionTask from the supplied URL request that will execute the completion block when it finishes.
 Note that -resume is NOT called on the task, which means that the caller will need to begin execution themselves.

 @param request The URL request to load data from.
 @param completion An optional block fired on completion of the request.
 @return An object that conforms to the NSURLSessionTask protocol. Can be used to cancel the request.
 */
- (NSURLSessionTask*)createURLSessionTask:(NSURLRequest*)request completion:(nullable OBADataSourceCompletion)completion;

/**
 Given an URL request, load its contents.

 @param request The URL request to load data from.
 @param completion An optional block fired on completion of the request.
 @return An object that conforms to the NSURLSessionTask protocol. Can be used to cancel the request.
 */
- (NSURLSessionTask*)performRequest:(NSURLRequest*)request completionBlock:(nullable OBADataSourceCompletion)completion;

/**
 Creates an NSURLSessionTask that uses the specified HTTP method.

 @param path            The server path to request.
 @param httpMethod      The method used to send the request to the server. e.g. GET, POST, or DELETE.
 @param queryParameters The arguments that are passed to the server.
 @param formBody        The form body. Only sent along for POST/PUT/PATCH requests.
 @param completion      The completion block.
 @return A connection object.
 */
- (NSURLSessionTask*)requestWithPath:(NSString*)path
                                    HTTPMethod:(NSString*)httpMethod
                               queryParameters:(nullable NSDictionary*)queryParameters
                                      formBody:(nullable NSDictionary*)formBody
                               completionBlock:(OBADataSourceCompletion) completion;


/**
 Cancels all open URL requests.
 */
- (void)cancelOpenConnections;

@end

NS_ASSUME_NONNULL_END

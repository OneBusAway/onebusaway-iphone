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

NS_ASSUME_NONNULL_BEGIN

@interface OBAJsonDataSource : NSObject
@property(nonatomic,strong) OBADataSourceConfig *config;
@property(nonatomic,strong) NSURLSession *URLSession;

+ (instancetype)JSONDataSourceWithBaseURL:(NSURL*)URL userID:(NSString*)userID;
+ (instancetype)googleMapsJSONDataSource;

/**
 OBA.co, obaco, or onebusaway.co is the service that powers deep links in the app,
 along with other cross-regional services.
 */
+ (instancetype)obacoJSONDataSource;

- (id)initWithConfig:(OBADataSourceConfig*)config;

/**
 Creates a mutable URL request based upon the supplied URL and HTTP method, configuring other parameters, like a GZIP header.

 @param URL The URL to load.
 @param HTTPMethod The HTTP method to load: GET, POST, PUT, PATCH, DELETE.
 @return A mutable URL request suitable for loading data.
 */
- (NSMutableURLRequest*)requestWithURL:(NSURL*)URL HTTPMethod:(NSString*)HTTPMethod;

/**
 Given an URL request, load its contents.

 @param request The URL request to load data from.
 @param completion A block fired on completion of the request.
 @return An object that conforms to the NSURLSessionTask protocol. Can be used to cancel the request.
 */
- (NSURLSessionTask*)performRequest:(NSURLRequest*)request completionBlock:(OBADataSourceCompletion)completion;

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

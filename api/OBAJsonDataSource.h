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

#import "OBADataSource.h"
#import "OBADataSourceConfig.h"

typedef void (^OBADataSourceCompletion)(id responseData, NSUInteger responseCode, NSError * error);
typedef void (^OBADataSourceProgress)(CGFloat progress);

@interface OBAJsonDataSource : NSObject

- (id)initWithConfig:(OBADataSourceConfig*)config;

- (NSURL*) urlWithPath:(NSString*)path withArgs:(NSString*)args;

- (id<OBADataSourceConnection>) requestWithPath:(NSString*)path
                                completionBlock:(OBADataSourceCompletion) completion;

- (id<OBADataSourceConnection>) requestWithPath:(NSString*)path
                                       withArgs:(NSString*)args
                                completionBlock:(OBADataSourceCompletion) completion
                                  progressBlock:(OBADataSourceProgress) progress;

- (id<OBADataSourceConnection>) requestWithPath:(NSString*)path
                                       withArgs:(NSString*)args
                                 withFileUpload:(NSString*)filePath
                                completionBlock:(OBADataSourceCompletion) completion
                                  progressBlock:(OBADataSourceProgress) progress;

- (id<OBADataSourceConnection>) postWithPath:(NSString*)url
                                    withArgs:(NSDictionary*)args
                             completionBlock:(OBADataSourceCompletion) completion
                               progressBlock:(OBADataSourceProgress) progress;

- (void) cancelOpenConnections;

@end

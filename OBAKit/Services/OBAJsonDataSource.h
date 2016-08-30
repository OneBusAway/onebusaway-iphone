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
@import UIKit;

#import "OBADataSource.h"
#import "OBADataSourceConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAJsonDataSource : NSObject
@property(nonatomic,strong) OBADataSourceConfig *config;

+ (instancetype)JSONDataSourceWithBaseURL:(NSURL*)URL userID:(NSString*)userID;
+ (instancetype)googleMapsJSONDataSource;

- (id)initWithConfig:(OBADataSourceConfig*)config;

- (id<OBADataSourceConnection>)requestWithPath:(NSString*)path
                                      withArgs:(nullable NSDictionary*)args
                               completionBlock:(OBADataSourceCompletion) completion
                                 progressBlock:(nullable OBADataSourceProgress) progress;

- (void)cancelOpenConnections;

@end

NS_ASSUME_NONNULL_END
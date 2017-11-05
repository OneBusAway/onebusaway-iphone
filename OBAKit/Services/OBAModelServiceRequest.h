/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@import Foundation;
#import <OBAKit/OBAModelFactory.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^OBADataSourceCompletion)(_Nullable id responseData, NSHTTPURLResponse *response,  NSError * _Nullable error);

@interface OBAModelServiceRequest : NSObject

@property(strong) OBAModelFactory * modelFactory;
@property(assign,nullable) SEL modelFactorySelector;
@property(copy,nullable) UIBackgroundTaskIdentifier (^cleanupBlock)(UIBackgroundTaskIdentifier task);

@property BOOL checkCode;

@property UIBackgroundTaskIdentifier bgTask;
/**
 *  This has to be weak to avoid retain cycles between the "Connection" object and this service request.  The connection may hold a strong reference 
 *  to this request to perform some post processing on the data.
 */
@property (nonatomic, weak) NSURLSessionTask *connection;

- (void)processData:(id)obj withError:(NSError*)error response:(NSHTTPURLResponse*)response completionBlock:(OBADataSourceCompletion)completion;

- (void)cancel;
@end

NS_ASSUME_NONNULL_END

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

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OBADataSourceContentType) {
    OBADataSourceContentTypeJSON = 0,
    OBADataSourceContentTypeRaw,
};

@interface OBADataSourceConfig : NSObject
@property(nonatomic,assign,readonly) BOOL checkStatusCodeInBody;
@property(nonatomic,assign) OBADataSourceContentType contentType;

- (instancetype)initWithBaseURL:(NSURL*)URL userID:(nullable NSString*)userID checkStatusCodeInBody:(BOOL)checkStatusCodeInBody;

- (instancetype)initWithBaseURL:(NSURL*)URL userID:(nullable NSString*)userID checkStatusCodeInBody:(BOOL)checkStatusCodeInBody apiKey:(nullable NSString*)apiKey bundleVersion:(nullable NSString*)bundleVersion apiVersion:(nullable NSString*)apiVersion;

- (nullable NSURL*)constructURL:(NSString*)path withArgs:(nullable NSDictionary*)args;
@end

NS_ASSUME_NONNULL_END

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
@import MapKit;

#import <OBAKit/OBACommon.h>
#import <OBAKit/OBASearchType.h>

NS_ASSUME_NONNULL_BEGIN

@class OBAPlacemark;
@class OBARouteV2;

extern NSString * const kOBASearchTypeParameter;
extern NSString * const OBAStopIDNavigationTargetParameter;
extern NSString * const OBANavigationTargetSearchKey;
extern NSString * const kOBASearchControllerSearchLocationParameter;
extern NSString * const OBAUserSearchQueryKey;

@interface OBANavigationTarget : NSObject <NSCoding, NSCopying>
@property(nonatomic,assign,readonly) OBANavigationTargetType target;
@property(nonatomic,strong,readonly) NSDictionary * parameters;
@property(nonatomic,assign,readonly) OBASearchType searchType;
@property(nonatomic,strong,readonly,nullable) id searchArgument;
@property(nonatomic,copy,readonly,nullable) NSString *userFacingSearchQuery;

+ (instancetype)navigationTarget:(OBANavigationTargetType)target;
+ (instancetype)navigationTarget:(OBANavigationTargetType)target parameters:(nullable NSDictionary*)parameters;

- (void)setObject:(id)object forParameter:(NSString*)parameter;
@end

@interface OBANavigationTarget (Builders)
+ (instancetype)navigationTargetForSearchNone;
+ (instancetype)navigationTargetForSearchLocationRegion:(MKCoordinateRegion)region;
+ (instancetype)navigationTargetForSearchRoute:(NSString*)routeQuery;
+ (instancetype)navigationTargetForRoute:(OBARouteV2*)route;
+ (instancetype)navigationTargetForSearchAddress:(NSString*)addressQuery;
+ (instancetype)navigationTargetForSearchPlacemark:(OBAPlacemark*)placemark;
+ (instancetype)navigationTargetForStopID:(NSString*)stopID;
+ (instancetype)navigationTargetForStopIDSearch:(NSString*)stopID;
@end

NS_ASSUME_NONNULL_END

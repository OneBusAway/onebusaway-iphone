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

typedef NS_ENUM(NSUInteger, OBASortTripsByTypeV2) {
    OBASortTripsByDepartureTimeV2 = 0,
    OBASortTripsByRouteNameV2 = 1
};

NS_ASSUME_NONNULL_BEGIN

@interface OBAStopPreferencesV2 : NSObject <NSCoding> {
    OBASortTripsByTypeV2 _sortTripsByType;
    NSMutableSet * _routeFilter;
}
@property(nonatomic,assign) OBASortTripsByTypeV2 sortTripsByType;
@property(nonatomic,copy,readonly) NSString *formattedSortTripsByType;
@property(nonatomic,strong,readonly) NSSet * routeFilter;

/**
 This property will return YES if this stop has any filtered (i.e. hidden) routes.
 */
@property(nonatomic,assign,readonly) BOOL hasFilteredRoutes;

- (instancetype)initWithStopPreferences:(OBAStopPreferencesV2*)preferences;

/**
 Has the specified route ID been disabled by the user in the filtering and sorting prefences for this stop?

 @param routeID The route ID string.

 @return Whether this route has been disabled by the user.
 */
- (BOOL)isRouteIDDisabled:(NSString*)routeID;

- (BOOL)isRouteIdEnabled:(NSString*)routeId __deprecated;
- (void)setEnabled:(BOOL)isEnabled forRouteId:(NSString*)routeId;

/**
 If the route ID is NO, set it to YES. If it is YES, set it to NO. If it is not specified, set it to NO.

 @param routeID The route ID.

 @return Whether the the route is disabled or not.
 */
- (BOOL)toggleRouteID:(NSString*)routeID;

@end

NS_ASSUME_NONNULL_END

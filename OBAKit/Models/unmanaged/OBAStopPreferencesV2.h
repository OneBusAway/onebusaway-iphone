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
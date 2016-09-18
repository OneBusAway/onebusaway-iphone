#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBARouteV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAStopsForRouteV2 : OBAHasReferencesV2 {
    NSString * _routeId;
    NSMutableArray * _stopIds;
    NSMutableArray * _polylines;
}

@property (nonatomic, strong) NSString * routeId;
@property (weak, nonatomic, readonly) OBARouteV2 * route;
@property (weak, nonatomic, readonly) NSArray * stops;
@property (weak, nonatomic, readonly) NSArray * polylines;

- (id) initWithReferences:(OBAReferencesV2*)refs;

- (void) addStopId:(NSString*)stopId;
- (void) addPolyline:(NSString*)polyline;

@end

NS_ASSUME_NONNULL_END

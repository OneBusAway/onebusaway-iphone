#import "OBAHasReferencesV2.h"
#import "OBARouteV2.h"


@interface OBAStopsForRouteV2 : OBAHasReferencesV2 {
	NSString * _routeId;
	NSMutableArray * _stopIds;
}

@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, readonly) OBARouteV2 * route;
@property (nonatomic, readonly) NSArray * stops;

- (id) initWithReferences:(OBAReferencesV2*)refs;

- (void) addStopId:(NSString*)stopId;

@end

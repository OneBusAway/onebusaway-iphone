#import "OBAHasReferencesV2.h"


@interface OBAStopsForRouteV2 : OBAHasReferencesV2 {
	NSMutableArray * _stopIds;
}

@property (nonatomic, readonly) NSArray * stops;

- (void) addStopId:(NSString*)stopId;

@end

#import "OBAStopsForRouteV2.h"
#import "OBAStopV2.h"


@implementation OBAStopsForRouteV2

- (id) init {
	if(self = [super init]) {
		_stopIds = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_stopIds release];
	[super dealloc];
}

- (void) addStopId:(NSString*)stopId {
	[_stopIds addObject:stopId];
}

- (NSArray*) stops {
	NSMutableArray * stops = [[NSMutableArray alloc] init];
	OBAReferencesV2 * refs = [self references];
	for( NSString * stopId in _stopIds ) {
		OBAStopV2 * stop = [refs getStopForId:stopId];
		if( stop )
			[stops addObject:stop];
	}
	return stops;
}

@end

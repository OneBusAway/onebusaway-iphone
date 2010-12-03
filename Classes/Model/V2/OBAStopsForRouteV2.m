#import "OBAStopsForRouteV2.h"
#import "OBAStopV2.h"


@implementation OBAStopsForRouteV2

@synthesize routeId = _routeId;

- (id) initWithReferences:(OBAReferencesV2*)refs {
	if(self = [super initWithReferences:refs]) {
		_stopIds = [[NSMutableArray alloc] init];
		_polylines = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_routeId release];
	[_stopIds release];
	[_polylines release];
	[super dealloc];
}

- (void) addStopId:(NSString*)stopId {
	[_stopIds addObject:stopId];
}

- (void) addPolyline:(NSString*)polyline {
	[_polylines addObject:polyline];
}

- (OBARouteV2*) route {
	return [_references getRouteForId:_routeId];
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

- (NSArray*) polylines {
	return _polylines;
}
	
@end

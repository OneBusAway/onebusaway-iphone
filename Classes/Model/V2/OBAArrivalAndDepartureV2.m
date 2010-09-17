#import "OBAArrivalAndDepartureV2.h"


@implementation OBAArrivalAndDepartureV2

@synthesize routeId = _routeId;
@synthesize routeShortName = _routeShortName;
@synthesize tripId = _tripId;
@synthesize serviceDate;
@synthesize tripHeadsign = _tripHeadsign;
@synthesize stopId = _stopId;

@synthesize scheduledArrivalTime = _scheduledArrivalTime;
@synthesize predictedArrivalTime = _predictedArrivalTime;

@synthesize scheduledDepartureTime = _scheduledDepartureTime;
@synthesize predictedDepartureTime = _predictedDepartureTime;

- (void) dealloc {
	[_routeId release];
	[_routeShortName release];
	[_tripId release];
	[_tripHeadsign release];
	[_stopId release];
	
	[super dealloc];
}

- (OBARouteV2*) route {
	OBAReferencesV2 * refs = [self references];
	return [refs getRouteForId:_routeId];
}

- (OBAStopV2*) stop {
	OBAReferencesV2 * refs = [self references];
	return [refs getStopForId:_stopId];
}

- (long long) bestArrivalTime {
	return _predictedArrivalTime == 0 ? _scheduledArrivalTime : _predictedArrivalTime;
}

- (long long) bestDepartureTime {
	return _predictedDepartureTime == 0 ? _scheduledDepartureTime : _predictedDepartureTime;
}

@end

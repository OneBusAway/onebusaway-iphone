#import "OBAArrivalAndDepartureV2.h"


@implementation OBAArrivalAndDepartureV2

@synthesize routeId = _routeId;
@synthesize routeShortName = _routeShortName;
@synthesize tripId = _tripId;
@synthesize serviceDate;
@synthesize tripHeadsign = _tripHeadsign;
@synthesize stopId = _stopId;
@synthesize stopSequence = _stopSequence;
@synthesize tripStatus = _tripStatus;
@synthesize distanceFromStop;
//@synthesize frequency = _frequency;

@synthesize predicted;

@synthesize scheduledArrivalTime = _scheduledArrivalTime;
@synthesize predictedArrivalTime = _predictedArrivalTime;

@synthesize scheduledDepartureTime = _scheduledDepartureTime;
@synthesize predictedDepartureTime = _predictedDepartureTime;

@synthesize situationIds = _situationIds;

- (id) init {
	if (self = [super init]) {
		_situationIds = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_routeId release];
	[_routeShortName release];
	[_tripId release];
	[_tripHeadsign release];
	[_stopId release];
	[_frequency release];
	[_situationIds release];
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

- (OBATripV2*) trip {
	OBAReferencesV2 * refs = [self references];
	return [refs getTripForId:_tripId];

}

- (OBAArrivalAndDepartureInstanceRef *) instance {
	return [OBAArrivalAndDepartureInstanceRef refWithTripInstance:self.tripInstance stopId:_stopId stopSequence:_stopSequence];
}

- (OBATripInstanceRef *) tripInstance {
	return [OBATripInstanceRef tripInstance:self.tripId serviceDate:self.serviceDate vehicleId:self.tripStatus.vehicleId];
}

- (long long) bestArrivalTime {
	return _predictedArrivalTime == 0 ? _scheduledArrivalTime : _predictedArrivalTime;
}

- (long long) bestDepartureTime {
	return _predictedDepartureTime == 0 ? _scheduledDepartureTime : _predictedDepartureTime;
}

- (NSArray*) situations {
	
	NSMutableArray * rSituations = [NSMutableArray array];
	
	OBAReferencesV2 * refs = self.references;
	
	for( NSString * situationId in self.situationIds ) {
		OBASituationV2 * situation = [refs getSituationForId:situationId];
		if( situation )
			[rSituations addObject:situation];
	}
	
	return rSituations;
}

- (void) addSituationId:(NSString*)situationId {
	[_situationIds addObject:situationId];
}

- (void) setFrequency:(OBAFrequencyV2*)frequency {
	_frequency = [frequency retain];
}

- (OBAFrequencyV2*) frequency {
	return _frequency;
}

@end

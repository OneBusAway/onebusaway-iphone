#import "OBAReferencesV2.h"
#import "OBAAgencyV2.h"
#import "OBARouteV2.h"
#import "OBAStopV2.h"
#import "OBATripV2.h"
#import "OBASituationV2.h"


@implementation OBAReferencesV2

-(id) init {
    self = [super init];
	if( self ) {
		_agencies = [[NSMutableDictionary alloc] init];
		_routes = [[NSMutableDictionary alloc] init];
		_stops = [[NSMutableDictionary alloc] init];
		_trips = [[NSMutableDictionary alloc] init];
		_situations = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (void) addAgency:(OBAAgencyV2*)agency {
	_agencies[agency.agencyId] = agency;
}

- (OBAAgencyV2*) getAgencyForId:(NSString*)agencyId {
	return _agencies[agencyId];
}	

- (void) addRoute:(OBARouteV2*)route {
	_routes[route.routeId] = route;
}

- (OBARouteV2*) getRouteForId:(NSString*)routeId {
	return _routes[routeId];
}	

- (void) addStop:(OBAStopV2*)stop {
	_stops[stop.stopId] = stop;
}

- (OBAStopV2*) getStopForId:(NSString*)stopId {
	return _stops[stopId];
}

- (void) addTrip:(OBATripV2*)trip {
	_trips[trip.tripId] = trip;
}

- (OBATripV2*) getTripForId:(NSString*)tripId {
	return _trips[tripId];
}

- (void) addSituation:(OBASituationV2*)situation {
	_situations[situation.situationId] = situation;
}

- (OBASituationV2*) getSituationForId:(NSString*)situationId {
	return _situations[situationId];
}

- (void) clear {
	[_agencies removeAllObjects];
	[_routes removeAllObjects];
	[_stops removeAllObjects];
	[_trips removeAllObjects];
	[_situations removeAllObjects];
}

- (NSString*) description {
	return [NSString stringWithFormat:@"%@ agencies:%d routes:%d stops:%d trips:%d situations:%d",
			[super description],
			[_agencies count],
			[_routes count],
			[_stops count],
			[_trips count],
			[_situations count]];
}

@end

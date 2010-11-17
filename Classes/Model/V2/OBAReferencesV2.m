#import "OBAReferencesV2.h"
#import "OBAAgencyV2.h"
#import "OBARouteV2.h"
#import "OBAStopV2.h"
#import "OBATripV2.h"
#import "OBASituationV2.h"


@implementation OBAReferencesV2

-(id) init {
	if( self = [super init] ) {
		_agencies = [[NSMutableDictionary alloc] init];
		_routes = [[NSMutableDictionary alloc] init];
		_stops = [[NSMutableDictionary alloc] init];
		_trips = [[NSMutableDictionary alloc] init];
		_situations = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_agencies release];
	[_routes release];
	[_stops release];
	[_trips release];
	[_situations release];
	[super dealloc];
}

- (void) addAgency:(OBAAgencyV2*)agency {
	[_agencies setObject:agency forKey:agency.agencyId];
}

- (OBAAgencyV2*) getAgencyForId:(NSString*)agencyId {
	return [_agencies objectForKey:agencyId];
}	

- (void) addRoute:(OBARouteV2*)route {
	[_routes setObject:route forKey:route.routeId];
}

- (OBARouteV2*) getRouteForId:(NSString*)routeId {
	return [_routes objectForKey:routeId];
}	

- (void) addStop:(OBAStopV2*)stop {
	[_stops setObject:stop forKey:stop.stopId];
}

- (OBAStopV2*) getStopForId:(NSString*)stopId {
	return [_stops objectForKey:stopId];
}

- (void) addTrip:(OBATripV2*)trip {
	[_trips setObject:trip forKey:trip.tripId];
}

- (OBATripV2*) getTripForId:(NSString*)tripId {
	return [_trips objectForKey:tripId];
}

- (void) addSituation:(OBASituationV2*)situation {
	[_situations setObject:situation forKey:situation.situationId];
}

- (OBASituationV2*) getSituationForId:(NSString*)situationId {
	return [_situations objectForKey:situationId];
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

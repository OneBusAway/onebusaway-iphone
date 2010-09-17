#import "OBAReferencesV2.h"
#import "OBAAgencyV2.h"
#import "OBARouteV2.h"
#import "OBAStopV2.h"


@implementation OBAReferencesV2

-(id) init {
	if( self = [super init] ) {
		_agencies = [[NSMutableDictionary alloc] init];
		_routes = [[NSMutableDictionary alloc] init];
		_stops = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_agencies release];
	[_routes release];
	[_stops release];
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

@end

@class OBAAgencyV2;
@class OBARouteV2;
@class OBAStopV2;
@class OBATripV2;


@interface OBAReferencesV2 : NSObject {
	NSMutableDictionary * _agencies;
	NSMutableDictionary * _routes;
	NSMutableDictionary * _stops;
	NSMutableDictionary * _trips;
}

- (void) addAgency:(OBAAgencyV2*)agency;
- (OBAAgencyV2*) getAgencyForId:(NSString*)agencyId;

- (void) addRoute:(OBARouteV2*)route;
- (OBARouteV2*) getRouteForId:(NSString*)routeId;

- (void) addStop:(OBAStopV2*)stop;
- (OBAStopV2*) getStopForId:(NSString*)stopId;

- (void) addTrip:(OBATripV2*)trip;
- (OBATripV2*) getTripForId:(NSString*)tripId;

- (void) clear;
							 
@end

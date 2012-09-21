@class OBAAgencyV2;
@class OBARouteV2;
@class OBAStopV2;
@class OBATripV2;
@class OBASituationV2;

@interface OBAReferencesV2 : NSObject {
	NSMutableDictionary * _agencies;
	NSMutableDictionary * _routes;
	NSMutableDictionary * _stops;
	NSMutableDictionary * _trips;
	NSMutableDictionary * _situations;
}

- (void) addAgency:(OBAAgencyV2*)agency;
- (OBAAgencyV2*) getAgencyForId:(NSString*)agencyId;

- (void) addRoute:(OBARouteV2*)route;
- (OBARouteV2*) getRouteForId:(NSString*)routeId;

- (void) addStop:(OBAStopV2*)stop;
- (OBAStopV2*) getStopForId:(NSString*)stopId;

- (void) addTrip:(OBATripV2*)trip;
- (OBATripV2*) getTripForId:(NSString*)tripId;

- (void) addSituation:(OBASituationV2*)situation;
- (OBASituationV2*) getSituationForId:(NSString*)situationId;

- (void) clear;
							 
@end

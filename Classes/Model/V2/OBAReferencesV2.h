@class OBAAgencyV2;
@class OBARouteV2;
@class OBAStopV2;


@interface OBAReferencesV2 : NSObject {
	NSMutableDictionary * _agencies;
	NSMutableDictionary * _routes;
	NSMutableDictionary * _stops;
}

- (void) addAgency:(OBAAgencyV2*)agency;
- (OBAAgencyV2*) getAgencyForId:(NSString*)agencyId;

- (void) addRoute:(OBARouteV2*)route;
- (OBARouteV2*) getRouteForId:(NSString*)routeId;

- (void) addStop:(OBAStopV2*)stop;
- (OBAStopV2*) getStopForId:(NSString*)stopId;
							 
@end

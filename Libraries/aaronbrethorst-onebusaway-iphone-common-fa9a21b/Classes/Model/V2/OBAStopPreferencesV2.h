typedef enum {
	OBASortTripsByDepartureTimeV2=0,
	OBASortTripsByRouteNameV2=1
} OBASortTripsByTypeV2;


@interface OBAStopPreferencesV2 : NSObject <NSCoding> {
	OBASortTripsByTypeV2 _sortTripsByType;
	NSMutableSet * _routeFilter;
}

- (id) initWithStopPreferences:(OBAStopPreferencesV2*)preferences;
- (id) initWithCoder:(NSCoder*)coder;

@property (nonatomic) OBASortTripsByTypeV2 sortTripsByType;
@property (nonatomic,readonly) NSSet * routeFilter;

- (BOOL) isRouteIdEnabled:(NSString*) routeId;
- (void) setEnabled:(BOOL)isEnabled forRouteId:(NSString*)routeId;

@end
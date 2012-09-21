#import "OBAModelService.h"
#import "OBAModelServiceRequest.h"
#import "OBASearchController.h"
#import "OBASphericalGeometryLibrary.h"

static const float kSearchRadius = 400;


@interface OBAModelService (Private)

- (OBAModelServiceRequest*) request:(NSString*)url args:(NSString*)args selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context;
- (OBAModelServiceRequest*) request:(OBAJsonDataSource*)source url:(NSString*)url args:(NSString*)args selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context;

- (OBAModelServiceRequest*) post:(NSString*)url args:(NSDictionary*)args selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context;
- (OBAModelServiceRequest*) post:(OBAJsonDataSource*)source url:(NSString*)url args:(NSDictionary*)args selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context;

- (OBAModelServiceRequest*) request:(OBAJsonDataSource*)source selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context;


- (CLLocation*) currentOrDefaultLocationToSearch;
- (NSString*) escapeStringForUrl:(NSString*)url;
- (NSString*) argsFromDictionary:(NSDictionary*)args;

@end


@implementation OBAModelService

@synthesize modelDao = _modelDao;
@synthesize modelFactory = _modelFactory;
@synthesize references = _references;
@synthesize obaJsonDataSource = _obaJsonDataSource;
@synthesize googleMapsJsonDataSource = _googleMapsJsonDataSource;
@synthesize googlePlacesJsonDataSource = _googlePlacesJsonDataSource;
@synthesize locationManager = _locationManager;

@synthesize deviceToken;


- (id<OBAModelServiceRequest>) requestStopForId:(NSString*)stopId withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {

	stopId = [self escapeStringForUrl:stopId];
	
	NSString * url = [NSString stringWithFormat:@"/api/where/stop/%@.json", stopId];
	NSString * args = @"version=2";
	SEL selector = @selector(getStopFromJSON:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) requestStopWithArrivalsAndDeparturesForId:(NSString*)stopId withMinutesBefore:(NSUInteger)minutesBefore withMinutesAfter:(NSUInteger)minutesAfter withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	stopId = [self escapeStringForUrl:stopId];

	NSString *url = [NSString stringWithFormat:@"/api/where/arrivals-and-departures-for-stop/%@.json", stopId];
	NSString * args = [NSString stringWithFormat:@"version=2&minutesBefore=%d&minutesAfter=%d",minutesBefore,minutesAfter];
	SEL selector = @selector(getArrivalsAndDeparturesForStopV2FromJSON:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) requestStopsForRegion:(MKCoordinateRegion)region withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	CLLocationCoordinate2D coord = region.center;
	MKCoordinateSpan span = region.span;
	
	NSString * url = @"/api/where/stops-for-location.json";
	NSString * args = [NSString stringWithFormat:@"lat=%f&lon=%f&latSpan=%f&lonSpan=%f&version=2", coord.latitude, coord.longitude, span.latitudeDelta, span.longitudeDelta];
	SEL selector = @selector(getStopsV2FromJSON:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) requestStopsForQuery:(NSString*)stopQuery withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	CLLocation * location = [self currentOrDefaultLocationToSearch];
	CLLocationCoordinate2D coord = location.coordinate;
	
	stopQuery = [self escapeStringForUrl:stopQuery];
	
	NSString * url = @"/api/where/stops-for-location.json";
	NSString * args = [NSString stringWithFormat:@"lat=%f&lon=%f&query=%@&version=2", coord.latitude, coord.longitude,stopQuery];
	SEL selector = @selector(getStopsV2FromJSON:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];	
}

- (id<OBAModelServiceRequest>) requestStopsForRoute:(NSString*)routeId withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	routeId = [self escapeStringForUrl:routeId];
	
	NSString * url = [NSString stringWithFormat:@"/api/where/stops-for-route/%@.json", routeId];
	NSString * args = @"version=2";
	SEL selector = @selector(getStopsForRouteV2FromJSON:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) requestStopsForPlacemark:(OBAPlacemark*)placemark withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {

	// request search
	CLLocationCoordinate2D location = placemark.coordinate;
    
	MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location latRadius:kSearchRadius lonRadius:kSearchRadius];
	return [self requestStopsForRegion:region withDelegate:delegate withContext:context];
}

- (id<OBAModelServiceRequest>) requestRoutesForQuery:(NSString*)routeQuery withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {

	CLLocation * location = [self currentOrDefaultLocationToSearch];
	CLLocationCoordinate2D coord = location.coordinate;
	
	routeQuery = [self escapeStringForUrl:routeQuery];
	
	NSString * url = @"/api/where/routes-for-location.json";
	NSString * args = [NSString stringWithFormat:@"lat=%f&lon=%f&query=%@&version=2", coord.latitude, coord.longitude,routeQuery];
	SEL selector = @selector(getRoutesV2FromJSON:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) placemarksForAddress:(NSString*)address withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {

	// handle search
	CLLocation * location = [self currentOrDefaultLocationToSearch];
	CLLocationCoordinate2D coord = location.coordinate;
    
	address = [self escapeStringForUrl:address];
	
	NSString * url = @"/maps/geo";
	NSString * args = [NSString stringWithFormat:@"ll=%f,%f&spn=0.5,0.5&q=%@", coord.latitude, coord.longitude, address];
	SEL selector = @selector(getPlacemarksFromJSONObject:error:);
	
	return [self request:_googleMapsJsonDataSource url:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) placemarksForPlace:(NSString*)name withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
    
    // handle search
	CLLocation * location = [self currentOrDefaultLocationToSearch];
	CLLocationCoordinate2D coord = location.coordinate;
    
	name = [self escapeStringForUrl:name];
    
    NSInteger radius = location.horizontalAccuracy;
    if( radius == 0 )
        radius = kSearchRadius;
	
	NSString * url = @"/maps/api/place/search/json";
	NSString * args = [NSString stringWithFormat:@"location=%f,%f&radius=%d&name=%@&sensor=true", coord.latitude, coord.longitude, radius, name];
	SEL selector = @selector(getPlacemarksFromGooglePlacesJSONObject:error:);
	
	return [self request:_googlePlacesJsonDataSource url:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) requestAgenciesWithCoverageWithDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
    // update search filter description
    // self.searchFilterString = [NSString stringWithFormat:@"Transit Agencies"];
	
	NSString * url = @"/api/where/agencies-with-coverage.json";
	NSString * args = @"version=2";
	SEL selector = @selector(getAgenciesWithCoverageV2FromJson:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) requestArrivalAndDepartureForStop:(OBAArrivalAndDepartureInstanceRef*)instance withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	NSString * stopId = [self escapeStringForUrl:instance.stopId];
	OBATripInstanceRef * tripInstance = instance.tripInstance;
	
	NSString * url = [NSString stringWithFormat:@"/api/where/arrival-and-departure-for-stop/%@.json", stopId];
	NSMutableString * args = [NSMutableString stringWithString:@"version=2"];
	[args appendFormat:@"&tripId=%@",[self escapeStringForUrl:tripInstance.tripId]];
	[args appendFormat:@"&serviceDate=%lld",tripInstance.serviceDate];
	if( tripInstance.vehicleId )
		[args appendFormat:@"&vehicleId=%@",[self escapeStringForUrl:tripInstance.vehicleId]];
	if( instance.stopSequence >= 0 )
		[args appendFormat:@"&stopSequence=%d",instance.stopSequence];
	SEL selector = @selector(getArrivalAndDepartureForStopV2FromJSON:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) requestTripDetailsForTripInstance:(OBATripInstanceRef*)tripInstance withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	NSString * tripId = [self escapeStringForUrl:tripInstance.tripId];
	NSString * url = [NSString stringWithFormat:@"/api/where/trip-details/%@.json", tripId];
	NSMutableString * args = [NSMutableString stringWithString:@"version=2"];
	if( tripInstance.serviceDate > 0 )
		[args appendFormat:@"&serviceDate=%lld",tripInstance.serviceDate];
	if( tripInstance.vehicleId )
		[args appendFormat:@"&vehicleId=%@",[self escapeStringForUrl:tripInstance.vehicleId]];
	SEL selector = @selector(getTripDetailsV2FromJSON:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];	
}

- (id<OBAModelServiceRequest>) requestVehicleForId:(NSString*)vehicleId withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	vehicleId = [self escapeStringForUrl:vehicleId];
	
	NSString * url = [NSString stringWithFormat:@"/api/where/vehicle/%@.json",vehicleId];
	NSString * args = [NSString stringWithFormat:@"version=2"];
	SEL selector = @selector(getVehicleStatusV2FromJSON:error:);
	
	return [self request:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) requestShapeForId:(NSString*)shapeId withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {

	shapeId = [self escapeStringForUrl:shapeId];
	
	NSString * url = [NSString stringWithFormat:@"/api/where/shape/%@.json",shapeId];
	NSString * args = [NSString stringWithFormat:@"version=2"];
	SEL selector = @selector(getShapeV2FromJSON:error:);

	return [self request:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) reportProblemWithPlannedTrip:(OBAReportProblemWithPlannedTripV2*)problem withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
 
    NSString * url = [NSString stringWithFormat:@"/api/where/report-problem-with-planned-trip.json"];

    CLLocationCoordinate2D from = problem.fromLocation.coordinate;
    CLLocationCoordinate2D to = problem.toLocation.coordinate;
    BOOL arriveBy = problem.arriveBy;
    NSDate * t = problem.time;

    NSMutableDictionary *args = [NSMutableDictionary dictionaryWithDictionary:@{
        @"time": [NSString stringWithFormat:@"%lld",t],
        @"latFrom": [NSString stringWithFormat:@"%f",from.latitude],
        @"lonFrom": [NSString stringWithFormat:@"%f",from.longitude],
        @"latTo": [NSString stringWithFormat:@"%f",to.latitude],
        @"lonTo": [NSString stringWithFormat:@"%f",to.longitude],
        @"arriveBy": (arriveBy ? @"true" : @"false"),
        @"useRealTime": @"true"
                                 }];
	
	if( problem.data )
		args[@"data"] = problem.data;
	
	if( problem.userComment )
		args[@"userComment"] = problem.userComment;
	
	CLLocation * location = problem.userLocation;
	if( location ) {
		CLLocationCoordinate2D coord = location.coordinate;
		args[@"userLat"] = [NSString stringWithFormat:@"%f",coord.latitude];
		args[@"userLon"] = [NSString stringWithFormat:@"%f",coord.longitude];
		args[@"userLocationAccuracy"] = [NSString stringWithFormat:@"%f",location.horizontalAccuracy];
	}
	
	SEL selector = nil;
    
    NSString * argsValue = [self argsFromDictionary:args];
	
	OBAModelServiceRequest * request = [self request:url args:argsValue selector:selector delegate:delegate context:context];
	request.checkCode = NO;
	return request;
}

- (id<OBAModelServiceRequest>) reportProblemWithStop:(OBAReportProblemWithStopV2*)problem withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	NSString * url = [NSString stringWithFormat:@"/api/where/report-problem-with-stop.json"];
	
	NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
	args[@"version"] = @"2";
	args[@"stopId"] = problem.stopId;
	
	if( problem.data )
		args[@"data"] = problem.data;
	
	if( problem.userComment )
		args[@"userComment"] = problem.userComment;
	
	CLLocation * location = problem.userLocation;
	if( location ) {
		CLLocationCoordinate2D coord = location.coordinate;
		args[@"userLat"] = @(coord.latitude);
		args[@"userLon"] = @(coord.longitude);
		args[@"userLocationAccuracy"] = @(location.horizontalAccuracy);
	}
	
	SEL selector = nil;
	
	OBAModelServiceRequest * request = [self post:url args:args selector:selector delegate:delegate context:context];
	request.checkCode = NO;
	return request;
}

- (id<OBAModelServiceRequest>) reportProblemWithTrip:(OBAReportProblemWithTripV2*)problem withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	NSString * url = [NSString stringWithFormat:@"/api/where/report-problem-with-trip.json"];
	
	NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
	OBATripInstanceRef * tripInstance = problem.tripInstance;
	args[@"version"] = @"2";
	args[@"tripId"] = tripInstance.tripId;
	args[@"serviceDate"] = [NSString stringWithFormat:@"%lld",tripInstance.serviceDate];
	if( tripInstance.vehicleId ) {
		NSLog(@"vid=%@",tripInstance.vehicleId);
		args[@"vehicleId"] = tripInstance.vehicleId;
	}
	
	if( problem.stopId )	
		args[@"stopId"] = problem.stopId;
	
	if( problem.data )
		args[@"data"] = problem.data;
	
	if( problem.userComment )
		args[@"userComment"] = problem.userComment;
	
	args[@"userOnVehicle"] = (problem.userOnVehicle ? @"true" : @"false");

	if( problem.userVehicleNumber )
		args[@"userVehicleNumber"] = problem.userVehicleNumber;
	
	CLLocation * location = problem.userLocation;
	if( location ) {
		CLLocationCoordinate2D coord = location.coordinate;
		args[@"userLat"] = @(coord.latitude);
		args[@"userLon"] = @(coord.longitude);
		args[@"userLocationAccuracy"] = @(location.horizontalAccuracy);
	}
	
	SEL selector = nil;
	
	OBAModelServiceRequest * request = [self post:url args:args selector:selector delegate:delegate context:context];
	request.checkCode = NO;
	return request;
}

- (id<OBAModelServiceRequest>) requestCurrentVehicleEstimatesForLocations:(NSArray*)locations withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
    
    NSString * url = [NSString stringWithFormat:@"/api/where/estimate-current-vehicle.json"];
	
	NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
    
    NSMutableString * data = [[NSMutableString alloc] init];

    for( CLLocation * location in locations ) {
        if ([data length] > 0) {
            [data appendString:@"|"];
        }
        NSDate * time = location.timestamp;
        NSTimeInterval interval = [time timeIntervalSince1970];
        long long t = (interval * 1000);
        [data appendFormat:@"%lld",t];
        [data appendString:@","];
        [data appendFormat:@"%f",location.coordinate.latitude];
        [data appendString:@","];
        [data appendFormat:@"%f",location.coordinate.longitude];
        [data appendString:@","];
        [data appendFormat:@"%f",location.horizontalAccuracy];
    }
    
    args[@"data"] = data;
    
	SEL selector = @selector(getCurrentVehicleEstimatesV2FromJSON:error:);
    
    return [self request:url args:[self argsFromDictionary:args] selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) planTripFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to time:(NSDate*)time arriveBy:(BOOL)arriveBy options:(NSDictionary*)options delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context {
    
    NSString * url = [NSString stringWithFormat:@"/api/where/plan-trip.json"];
	
	NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
    
    NSTimeInterval interval = [time timeIntervalSince1970];
    long long t = (interval * 1000);
    
    args[@"time"] = [NSString stringWithFormat:@"%lld",t];
    args[@"latFrom"] = [NSString stringWithFormat:@"%f",from.latitude];
    args[@"lonFrom"] = [NSString stringWithFormat:@"%f",from.longitude];
    args[@"latTo"] = [NSString stringWithFormat:@"%f",to.latitude];
    args[@"lonTo"] = [NSString stringWithFormat:@"%f",to.longitude];
    args[@"arriveBy"] = (arriveBy ? @"true" : @"false");
    args[@"useRealTime"] = @"true";
    
    // Append all options
    for (NSString * key in options ) {
        args[key] = options[key];
    }
        
	SEL selector = @selector(getItinerariesV2FromJSON:error:);
    
    NSString * argsValue = [self argsFromDictionary:args];
    
    return [self request:url args:argsValue selector:selector delegate:delegate context:context];
    //return [self post:url args:args selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) registerAlarmForArrivalAndDepartureAtStop:(OBAArrivalAndDepartureInstanceRef*)instance onArrival:(BOOL)onArrival alarmTimeOffset:(NSInteger)alarmTimeOffset notificationOptions:(NSDictionary*)notificationOptions withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
    
    NSString * stopId = [self escapeStringForUrl:instance.stopId];
	OBATripInstanceRef * tripInstance = instance.tripInstance;
	
	NSString * url = [NSString stringWithFormat:@"/api/where/register-alarm-for-arrival-and-departure-at-stop/%@.json", stopId];
    
    NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
    args[@"tripId"] = tripInstance.tripId;
    args[@"serviceDate"] = [NSString stringWithFormat:@"%lld",tripInstance.serviceDate];
	if( tripInstance.vehicleId )
		args[@"vehicleId"] = tripInstance.vehicleId;
	if( instance.stopSequence >= 0 )
        args[@"stopSequence"] = [NSString stringWithFormat:@"%d",instance.stopSequence];
    
    if( onArrival )
        args[@"onArrival"] = @"true";
    
    if( alarmTimeOffset != 0 )
        args[@"alarmTimeOffset"] = [NSString stringWithFormat:@"%d",alarmTimeOffset];
    
    if (notificationOptions) {

        NSData *data = [NSJSONSerialization dataWithJSONObject:notificationOptions options:0 error:nil];
        NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        if (json)
        {
            args[@"data"] = json;
        }
    }
    
    NSData * token = self.deviceToken;
    const unsigned char * tokenBuffer = [token bytes];
    NSMutableString * tokenString = [[NSMutableString alloc] initWithString:@"apns:"];
    for( NSInteger i=0; i < [token length]; i++)
        [tokenString appendFormat:@"%02X",(unsigned long)(tokenBuffer[i])];
    args[@"url"] = tokenString;
    NSLog(@"Token String: %@ %d",tokenString,[token length]);
    
    SEL selector = @selector(getAlarmIdFromJSON:error:);
                                   
    NSString * argsValue = [self argsFromDictionary:args];
	
	return [self request:url args:argsValue selector:selector delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) cancelAlarmWithId:(NSString*)alarmId withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {

    alarmId = [self escapeStringForUrl:alarmId];
	
	NSString * url = [NSString stringWithFormat:@"/api/where/cancel-alarm/%@.json",alarmId];
    
	return [self request:url args:nil selector:nil delegate:delegate context:context];
}

- (id<OBAModelServiceRequest>) cancelAlarmsWithIds:(NSArray*)alarmIds withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
    
    NSString * url = @"/api/where/cancel-alarms.json";

    NSMutableString * args = [NSMutableString string];
    for( __strong NSString * alarmId in alarmIds ) {
        alarmId = [self escapeStringForUrl:alarmId];
        if( [args length] > 0 )
            [args appendString:@"&"];
        [args appendString:alarmId];
    }
    
	return [self request:url args:args selector:nil delegate:delegate context:context];
}

@end



@implementation OBAModelService (Private)


- (OBAModelServiceRequest*) request:(NSString*)url args:(NSString*)args selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context {
	return [self request:_obaJsonDataSource url:url args:args selector:selector delegate:delegate context:context];
}

- (OBAModelServiceRequest*) request:(OBAJsonDataSource*)source url:(NSString*)url args:(NSString*)args selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context {
	OBAModelServiceRequest * request = [self request:source selector:selector delegate:delegate context:context];
	request.connection = [source requestWithPath:url withArgs:args withDelegate:request context:nil];	
	return request;
}

- (OBAModelServiceRequest*) post:(NSString*)url args:(NSDictionary*)args selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context {
	return [self post:_obaJsonDataSource url:url args:args selector:selector delegate:delegate context:context];
}

- (OBAModelServiceRequest*) post:(OBAJsonDataSource*)source url:(NSString*)url args:(NSDictionary*)args selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context {
	OBAModelServiceRequest * request = [self request:source selector:selector delegate:delegate context:context];
	request.connection = [source postWithPath:url withArgs:args withDelegate:request context:nil];
	return request;	
}

- (OBAModelServiceRequest*) request:(OBAJsonDataSource*)source selector:(SEL)selector delegate:(id<OBAModelServiceDelegate>)delegate context:(id)context {

	OBAModelServiceRequest * request = [[OBAModelServiceRequest alloc] init];
	request.delegate = delegate;
	request.context = context;
	request.modelFactory = _modelFactory;
	request.modelFactorySelector = selector;
	
	if( source != _obaJsonDataSource )
		request.checkCode = NO;
	
	// if we support background task completion (iOS >= 4.0), allow our requests to complete
	// even if the user switches the foreground application.
	if ([[UIDevice currentDevice] isMultitaskingSupported]) {
		UIApplication* app = [UIApplication sharedApplication];
		request.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
			[request endBackgroundTask];
		}];
	}
	
	return request;
}

- (CLLocation*) currentOrDefaultLocationToSearch {
	
	CLLocation * location = _locationManager.currentLocation;
	
	if( ! location )
		location = _modelDao.mostRecentLocation;
	
	if( ! location )
		location = [[CLLocation alloc] initWithLatitude:47.61229680032385  longitude:-122.3386001586914];
	
	return location;
}

- (NSString*) escapeStringForUrl:(NSString*)url {
	url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSMutableString *escaped = [NSMutableString stringWithString:url];
	NSRange wholeString = NSMakeRange(0, [escaped length]);
	[escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:wholeString];
	return escaped;
}

- (NSString*) argsFromDictionary:(NSDictionary*)args {
    NSMutableString * s = [NSMutableString string];
    for (NSString * key in args ) {
        if( [s length] > 0 )
            [s appendString:@"&"];
        [s appendString:[self escapeStringForUrl:key]];
        [s appendString:@"="];
        [s appendString:[self escapeStringForUrl:args[key]]];
    }
    return s;
}

@end
#import "OBAModelService.h"
#import "OBAModelServiceRequest.h"
#import "UIDeviceExtensions.h"
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

@end


@implementation OBAModelService

@synthesize modelDao = _modelDao;
@synthesize modelFactory = _modelFactory;
@synthesize references = _references;
@synthesize obaJsonDataSource = _obaJsonDataSource;
@synthesize googleMapsJsonDataSource = _googleMapsJsonDataSource;
@synthesize locationManager = _locationManager;

- (void) dealloc {
	[_references release];
	[_modelDao release];
	[_modelFactory release];
	[_obaJsonDataSource release];
	[_googleMapsJsonDataSource release];
	[_locationManager release];
	[super dealloc];
}

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

- (id<OBAModelServiceRequest>) reportProblemWithStop:(OBAReportProblemWithStopV2*)problem withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	NSString * url = [NSString stringWithFormat:@"/api/where/report-problem-with-stop.json"];
	
	NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
	[args setObject:@"2" forKey:@"version"];
	[args setObject:problem.stopId forKey:@"stopId"];
	
	if( problem.data )
		[args setObject:problem.data forKey:@"data"];
	
	if( problem.userComment )
		[args setObject:problem.userComment forKey:@"userComment"];
	
	CLLocation * location = problem.userLocation;
	if( location ) {
		CLLocationCoordinate2D coord = location.coordinate;
		[args setObject:[NSNumber numberWithDouble:coord.latitude] forKey:@"userLat"];
		[args setObject:[NSNumber numberWithDouble:coord.longitude] forKey:@"userLon"];
		[args setObject:[NSNumber numberWithDouble:location.horizontalAccuracy] forKey:@"userLocationAccuracy"];
	}
	
	SEL selector = nil;
	
	OBAModelServiceRequest * request = [self post:url args:args selector:selector delegate:delegate context:context];
	request.checkCode = FALSE;
	return request;
}

- (id<OBAModelServiceRequest>) reportProblemWithTrip:(OBAReportProblemWithTripV2*)problem withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context {
	
	NSString * url = [NSString stringWithFormat:@"/api/where/report-problem-with-trip.json"];
	
	NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
	OBATripInstanceRef * tripInstance = problem.tripInstance;
	[args setObject:@"2" forKey:@"version"];
	[args setObject:tripInstance.tripId forKey:@"tripId"];
	[args setObject:[NSString stringWithFormat:@"%lld",tripInstance.serviceDate] forKey:@"serviceDate"];
	if( tripInstance.vehicleId ) {
		NSLog(@"vid=%@",tripInstance.vehicleId);
		[args setObject:tripInstance.vehicleId forKey:@"vehicleId"];
	}
	
	if( problem.stopId )	
		[args setObject:problem.stopId forKey:@"stopId"];
	
	if( problem.data )
		[args setObject:problem.data forKey:@"data"];
	
	if( problem.userComment )
		[args setObject:problem.userComment forKey:@"userComment"];
	
	[args setObject:(problem.userOnVehicle ? @"true" : @"false") forKey:@"userOnVehicle"];

	if( problem.userVehicleNumber )
		[args setObject:problem.userVehicleNumber forKey:@"userVehicleNumber"];
	
	CLLocation * location = problem.userLocation;
	if( location ) {
		CLLocationCoordinate2D coord = location.coordinate;
		[args setObject:[NSNumber numberWithDouble:coord.latitude] forKey:@"userLat"];
		[args setObject:[NSNumber numberWithDouble:coord.longitude] forKey:@"userLon"];
		[args setObject:[NSNumber numberWithDouble:location.horizontalAccuracy] forKey:@"userLocationAccuracy"];
	}
	
	SEL selector = nil;
	
	OBAModelServiceRequest * request = [self post:url args:args selector:selector delegate:delegate context:context];
	request.checkCode = FALSE;
	return request;
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

	OBAModelServiceRequest * request = [[[OBAModelServiceRequest alloc] init] autorelease];
	request.delegate = delegate;
	request.context = context;
	request.modelFactory = _modelFactory;
	request.modelFactorySelector = selector;
	
	if( source != _obaJsonDataSource )
		request.checkCode = FALSE;
	
	// if we support background task completion (iOS >= 4.0), allow our requests to complete
	// even if the user switches the foreground application.
	if ([[UIDevice currentDevice] isMultitaskingSupportedSafe]) {
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
		location = [[[CLLocation alloc] initWithLatitude:47.61229680032385  longitude:-122.3386001586914] autorelease];
	
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

@end
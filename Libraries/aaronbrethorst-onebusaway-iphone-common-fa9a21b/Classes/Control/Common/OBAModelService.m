#import "OBAModelService.h"
#import "OBAModelServiceRequest.h"
#import "OBASearchController.h"
#import "OBASphericalGeometryLibrary.h"

static const float kSearchRadius = 400;
static const float kBigSearchRadius = 15000;

@implementation OBAModelService

@synthesize modelDao = _modelDao;
@synthesize modelFactory = _modelFactory;
@synthesize references = _references;
@synthesize obaJsonDataSource = _obaJsonDataSource;
@synthesize obaRegionJsonDataSource = _obaRegionJsonDataSource;
@synthesize googleMapsJsonDataSource = _googleMapsJsonDataSource;
@synthesize googlePlacesJsonDataSource = _googlePlacesJsonDataSource;
@synthesize locationManager = _locationManager;

@synthesize deviceToken;


- (id<OBAModelServiceRequest>)requestStopForId:(NSString *)stopId completionBlock:(OBADataSourceCompletion)completion {
    stopId = [self escapeStringForUrl:stopId];

    NSString *url = [NSString stringWithFormat:@"/api/where/stop/%@.json", stopId];
    NSString *args = @"version=2";
    SEL selector = @selector(getStopFromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestStopWithArrivalsAndDeparturesForId:(NSString *)stopId withMinutesBefore:(NSUInteger)minutesBefore withMinutesAfter:(NSUInteger)minutesAfter completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    stopId = [self escapeStringForUrl:stopId];

    NSString *url = [NSString stringWithFormat:@"/api/where/arrivals-and-departures-for-stop/%@.json", stopId];
    NSString *args = [NSString stringWithFormat:@"version=2&minutesBefore=%lu&minutesAfter=%lu", (unsigned long)minutesBefore, (unsigned long)minutesAfter];
    SEL selector = @selector(getArrivalsAndDeparturesForStopV2FromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:progress];
}

- (id<OBAModelServiceRequest>)requestStopsForRegion:(MKCoordinateRegion)region completionBlock:(OBADataSourceCompletion)completion; {
    CLLocationCoordinate2D coord = region.center;
    MKCoordinateSpan span = region.span;

    NSString *url = @"/api/where/stops-for-location.json";
    NSString *args = [NSString stringWithFormat:@"lat=%f&lon=%f&latSpan=%f&lonSpan=%f&version=2", coord.latitude, coord.longitude, span.latitudeDelta, span.longitudeDelta];
    SEL selector = @selector(getStopsV2FromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestStopsForQuery:(NSString *)stopQuery completionBlock:(OBADataSourceCompletion)completion {
    return [self requestStopsForQuery:stopQuery withRegion:nil completionBlock:completion];
}

- (id<OBAModelServiceRequest>)requestStopsForQuery:(NSString *)stopQuery withRegion:(CLRegion *)region completionBlock:(OBADataSourceCompletion)completion {
    CLLocationDistance radius = kBigSearchRadius;
    CLLocationCoordinate2D coord;

    if (region) {
        radius = region.radius > kBigSearchRadius ? region.radius : kBigSearchRadius;
        coord = region.center;
    }
    else {
        CLLocation *location = [self currentOrDefaultLocationToSearch];
        coord = location.coordinate;
    }

    stopQuery = [self escapeStringForUrl:stopQuery];

    NSString *url = @"/api/where/stops-for-location.json";
    NSString *args = [NSString stringWithFormat:@"lat=%f&lon=%f&query=%@&version=2&radius=%f", coord.latitude, coord.longitude, stopQuery, radius];
    SEL selector = @selector(getStopsV2FromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestStopsForRoute:(NSString *)routeId completionBlock:(OBADataSourceCompletion)completion {
    routeId = [self escapeStringForUrl:routeId];

    NSString *url = [NSString stringWithFormat:@"/api/where/stops-for-route/%@.json", routeId];
    NSString *args = @"version=2";
    SEL selector = @selector(getStopsForRouteV2FromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestStopsForPlacemark:(OBAPlacemark *)placemark completionBlock:(OBADataSourceCompletion)completion {
    // request search
    CLLocationCoordinate2D location = placemark.coordinate;

    MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location latRadius:kSearchRadius lonRadius:kSearchRadius];

    return [self requestStopsForRegion:region completionBlock:completion];
}

- (id<OBAModelServiceRequest>)requestRoutesForQuery:(NSString *)routeQuery completionBlock:(OBADataSourceCompletion)completion {
    return [self requestRoutesForQuery:routeQuery withRegion:nil completionBlock:completion];
}

- (id<OBAModelServiceRequest>)requestRoutesForQuery:(NSString *)routeQuery withRegion:(CLRegion *)region completionBlock:(OBADataSourceCompletion)completion {
    CLLocationDistance radius = kBigSearchRadius;
    CLLocationCoordinate2D coord;

    if (region) {
        radius = region.radius > kBigSearchRadius ? region.radius : kBigSearchRadius;
        coord = region.center;
    }
    else {
        CLLocation *location = [self currentOrDefaultLocationToSearch];
        coord = location.coordinate;
    }

    routeQuery = [self escapeStringForUrl:routeQuery];

    NSString *url = @"/api/where/routes-for-location.json";
    NSString *args = [NSString stringWithFormat:@"lat=%f&lon=%f&query=%@&version=2&radius=%f", coord.latitude, coord.longitude, routeQuery, radius];
    SEL selector = @selector(getRoutesV2FromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)placemarksForAddress:(NSString *)address completionBlock:(OBADataSourceCompletion)completion {
    // handle search
    CLLocation *location = [self currentOrDefaultLocationToSearch];
    CLLocationCoordinate2D coord = location.coordinate;

    address = [self escapeStringForUrl:address];
    address = [address stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];

    NSString *url = @"/maps/api/geocode/json";

    NSString *args = [[NSString stringWithFormat:@"bounds=%f,%f|%f,%f&address=%@", coord.latitude, coord.longitude, coord.latitude, coord.longitude, address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    SEL selector = @selector(getPlacemarksFromJSONObject:error:);

    return [self request:_googleMapsJsonDataSource url:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestRegions:(OBADataSourceCompletion)completion {
    NSString *url = @"/regions-v3.json";
    NSString *args = @"";
    SEL selector = @selector(getRegionsV2FromJson:error:);

    return [self request:_obaRegionJsonDataSource url:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)placemarksForPlace:(NSString *)name completionBlock:(OBADataSourceCompletion)completion {
    // handle search
    CLLocation *location = [self currentOrDefaultLocationToSearch];
    CLLocationCoordinate2D coord = location.coordinate;

    name = [self escapeStringForUrl:name];

    NSInteger radius = location.horizontalAccuracy;

    if (radius == 0) radius = kSearchRadius;

    NSString *url = @"/maps/api/place/search/json";
    NSString *args = [NSString stringWithFormat:@"location=%f,%f&radius=%ld&name=%@&sensor=true", coord.latitude, coord.longitude, (long)radius, name];
    SEL selector = @selector(getPlacemarksFromGooglePlacesJSONObject:error:);

    return [self request:_googlePlacesJsonDataSource url:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestAgenciesWithCoverage:(OBADataSourceCompletion)completion {
    // update search filter description
    // self.searchFilterString = [NSString stringWithFormat:@"Transit Agencies"];

    NSString *url = @"/api/where/agencies-with-coverage.json";
    NSString *args = @"version=2";
    SEL selector = @selector(getAgenciesWithCoverageV2FromJson:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestArrivalAndDepartureForStop:(OBAArrivalAndDepartureInstanceRef *)instance completionBlock:(OBADataSourceCompletion)completion {
    NSString *stopId = [self escapeStringForUrl:instance.stopId];
    OBATripInstanceRef *tripInstance = instance.tripInstance;

    NSString *url = [NSString stringWithFormat:@"/api/where/arrival-and-departure-for-stop/%@.json", stopId];
    NSMutableString *args = [NSMutableString stringWithString:@"version=2"];

    [args appendFormat:@"&tripId=%@", [self escapeStringForUrl:tripInstance.tripId]];
    [args appendFormat:@"&serviceDate=%lld", tripInstance.serviceDate];

    if (tripInstance.vehicleId) [args appendFormat:@"&vehicleId=%@", [self escapeStringForUrl:tripInstance.vehicleId]];

    if (instance.stopSequence >= 0) [args appendFormat:@"&stopSequence=%ld", (long)instance.stopSequence];

    SEL selector = @selector(getArrivalAndDepartureForStopV2FromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestTripDetailsForTripInstance:(OBATripInstanceRef *)tripInstance completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    NSString *tripId = [self escapeStringForUrl:tripInstance.tripId];
    NSString *url = [NSString stringWithFormat:@"/api/where/trip-details/%@.json", tripId];
    NSMutableString *args = [NSMutableString stringWithString:@"version=2"];

    if (tripInstance.serviceDate > 0) [args appendFormat:@"&serviceDate=%lld", tripInstance.serviceDate];

    if (tripInstance.vehicleId) [args appendFormat:@"&vehicleId=%@", [self escapeStringForUrl:tripInstance.vehicleId]];

    SEL selector = @selector(getTripDetailsV2FromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:progress];
}

- (id<OBAModelServiceRequest>)requestVehicleForId:(NSString *)vehicleId completionBlock:(OBADataSourceCompletion)completion {
    vehicleId = [self escapeStringForUrl:vehicleId];

    NSString *url = [NSString stringWithFormat:@"/api/where/vehicle/%@.json", vehicleId];
    NSString *args = [NSString stringWithFormat:@"version=2"];
    SEL selector = @selector(getVehicleStatusV2FromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestShapeForId:(NSString *)shapeId completionBlock:(OBADataSourceCompletion)completion {
    shapeId = [self escapeStringForUrl:shapeId];

    NSString *url = [NSString stringWithFormat:@"/api/where/shape/%@.json", shapeId];
    NSString *args = [NSString stringWithFormat:@"version=2"];
    SEL selector = @selector(getShapeV2FromJSON:error:);

    return [self request:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (id<OBAModelServiceRequest>)reportProblemWithStop:(OBAReportProblemWithStopV2 *)problem completionBlock:(OBADataSourceCompletion)completion {
    NSString *url = [NSString stringWithFormat:@"/api/where/report-problem-with-stop.json"];

    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];

    args[@"version"] = @"2";
    args[@"stopId"] = problem.stopId;

    if (problem.code) args[@"code"] = problem.code;

    if (problem.userComment) args[@"userComment"] = problem.userComment;

    if (problem.userLocation) {
        CLLocationCoordinate2D coord = problem.userLocation.coordinate;
        args[@"userLat"] = [@(coord.latitude)stringValue];
        args[@"userLon"] = [@(coord.longitude)stringValue];
        args[@"userLocationAccuracy"] = [@(problem.userLocation.horizontalAccuracy)stringValue];
    }

    SEL selector = nil;

    OBAModelServiceRequest *request = [self request:url args:[self argsFromDictionary:args] selector:selector completionBlock:completion progressBlock:nil];
    request.checkCode = YES;
    return request;
}

- (id<OBAModelServiceRequest>)reportProblemWithTrip:(OBAReportProblemWithTripV2 *)problem completionBlock:(OBADataSourceCompletion)completion {
    NSString *url = [NSString stringWithFormat:@"/api/where/report-problem-with-trip.json"];

    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    OBATripInstanceRef *tripInstance = problem.tripInstance;

    args[@"version"] = @"2";
    args[@"tripId"] = tripInstance.tripId;
    args[@"serviceDate"] = [NSString stringWithFormat:@"%lld", tripInstance.serviceDate];

    if (tripInstance.vehicleId) {
        NSLog(@"vid=%@", tripInstance.vehicleId);
        args[@"vehicleId"] = tripInstance.vehicleId;
    }

    if (problem.stopId) args[@"stopId"] = problem.stopId;

    if (problem.code) args[@"code"] = problem.code;

    if (problem.userComment) args[@"userComment"] = problem.userComment;

    args[@"userOnVehicle"] = (problem.userOnVehicle ? @"true" : @"false");

    if (problem.userVehicleNumber) args[@"userVehicleNumber"] = problem.userVehicleNumber;

    if (problem.userLocation) {
        CLLocationCoordinate2D coord = problem.userLocation.coordinate;
        args[@"userLat"] = [@(coord.latitude)stringValue];
        args[@"userLon"] = [@(coord.longitude)stringValue];
        args[@"userLocationAccuracy"] = [@(problem.userLocation.horizontalAccuracy)stringValue];
    }

    SEL selector = nil;

    OBAModelServiceRequest *request = [self request:url args:[self argsFromDictionary:args] selector:selector completionBlock:completion progressBlock:nil];
    request.checkCode = YES;
    return request;
}

- (id<OBAModelServiceRequest>)requestCurrentVehicleEstimatesForLocations:(NSArray *)locations completionBlock:(OBADataSourceCompletion)completion {
    NSString *url = [NSString stringWithFormat:@"/api/where/estimate-current-vehicle.json"];

    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];

    NSMutableString *data = [[NSMutableString alloc] init];

    for (CLLocation *location in locations) {
        if ([data length] > 0) {
            [data appendString:@"|"];
        }

        NSDate *time = location.timestamp;
        NSTimeInterval interval = [time timeIntervalSince1970];
        long long t = (interval * 1000);
        [data appendFormat:@"%lld", t];
        [data appendString:@","];
        [data appendFormat:@"%f", location.coordinate.latitude];
        [data appendString:@","];
        [data appendFormat:@"%f", location.coordinate.longitude];
        [data appendString:@","];
        [data appendFormat:@"%f", location.horizontalAccuracy];
    }

    args[@"data"] = data;

    SEL selector = @selector(getCurrentVehicleEstimatesV2FromJSON:error:);

    return [self request:url args:[self argsFromDictionary:args] selector:selector completionBlock:completion progressBlock:nil];
}

- (OBAModelServiceRequest *)request:(NSString *)url args:(NSString *)args selector:(SEL)selector completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    return [self request:_obaJsonDataSource url:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (OBAModelServiceRequest *)request:(OBAJsonDataSource *)source url:(NSString *)url args:(NSString *)args selector:(SEL)selector completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    OBAModelServiceRequest *request = [self request:source selector:selector];

    request.connection = [source requestWithPath:url
                                        withArgs:args
                                 completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                                     [request                       processData:jsonData
                                         withError:error
                                      responseCode:responseCode
                                         completionBlock:completion];
                                 }

                                   progressBlock:progress];
    return request;
}

- (OBAModelServiceRequest *)post:(NSString *)url args:(NSDictionary *)args selector:(SEL)selector completionBlock:(OBADataSourceCompletion)completion {
    return [self post:_obaJsonDataSource url:url args:args selector:selector completionBlock:completion progressBlock:nil];
}

- (OBAModelServiceRequest *)post:(OBAJsonDataSource *)source url:(NSString *)url args:(NSDictionary *)args selector:(SEL)selector completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    OBAModelServiceRequest *request = [self request:source selector:selector];

    request.connection = [source postWithPath:url
                                     withArgs:args
                              completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
                                  [request                       processData:responseData
                                         withError:error
                                      responseCode:responseCode
                                      completionBlock:completion];
                              }

                                progressBlock:progress];
    return request;
}

- (OBAModelServiceRequest *)request:(OBAJsonDataSource *)source selector:(SEL)selector {
    OBAModelServiceRequest *request = [[OBAModelServiceRequest alloc] init];

    request.modelFactory = _modelFactory;
    request.modelFactorySelector = selector;

    if (source != _obaJsonDataSource) request.checkCode = NO;

    // if we support background task completion (iOS >= 4.0), allow our requests to complete
    // even if the user switches the foreground application.
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        UIApplication *app = [UIApplication sharedApplication];
        request.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
                                  [request endBackgroundTask];
                              }];
    }

    return request;
}

- (CLLocation *)currentOrDefaultLocationToSearch {
    CLLocation *location = _locationManager.currentLocation;

    if (!location) location = _modelDao.mostRecentLocation;

    if (!location) location = [[CLLocation alloc] initWithLatitude:47.61229680032385  longitude:-122.3386001586914];

    return location;
}

- (NSString *)escapeStringForUrl:(NSString *)url {
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableString *escaped = [NSMutableString stringWithString:url];
    [escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    return escaped;
}

- (NSString *)argsFromDictionary:(NSDictionary *)args {
    NSMutableString *s = [NSMutableString string];

    for (NSString *key in args) {
        if ([s length] > 0) [s appendString:@"&"];

        [s appendString:[self escapeStringForUrl:key]];
        [s appendString:@"="];
        [s appendString:[self escapeStringForUrl:args[key]]];
    }

    return s;
}

@end
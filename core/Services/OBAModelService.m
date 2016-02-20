#import "OBAModelService.h"
#import "OBAModelServiceRequest.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBAURLHelpers.h"

static const CLLocationAccuracy kSearchRadius = 400;
static const CLLocationAccuracy kBigSearchRadius = 15000;

@implementation OBAModelService

- (AnyPromise*)requestStopForID:(NSString*)stopID {
    
    NSDictionary *args = @{ @"minutesBefore": @(5),
                            @"minutesAfter":  @(35) };
    
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self request:self.obaJsonDataSource
                  url:[NSString stringWithFormat:@"/api/where/arrivals-and-departures-for-stop/%@.json", stopID]
                 args:args
             selector:@selector(getArrivalsAndDeparturesForStopV2FromJSON:error:)
      completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
          
          if (error) {
              resolve(error);
          }
          else if (responseCode >= 300) {
              NSString *message = (404 == responseCode ? NSLocalizedString(@"Stop not found", @"code == 404") : NSLocalizedString(@"Error Connecting", @"code != 404"));
              error = [NSError errorWithDomain:NSURLErrorDomain code:responseCode userInfo:@{NSLocalizedDescriptionKey: message}];
              resolve(error);
          }
          else {
              resolve(responseData);
          }
      } progressBlock:nil];
    }];
}

- (id<OBAModelServiceRequest>)requestStopForId:(NSString *)stopId completionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/stop/%@.json", stopId]
                    args:nil
                selector:@selector(getStopFromJSON:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestStopWithArrivalsAndDeparturesForId:(NSString *)stopId withMinutesBefore:(NSUInteger)minutesBefore withMinutesAfter:(NSUInteger)minutesAfter completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {

    NSDictionary *args = @{ @"minutesBefore": @(minutesBefore),
                            @"minutesAfter":  @(minutesAfter) };

    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/arrivals-and-departures-for-stop/%@.json", stopId]
                    args:args
                selector:@selector(getArrivalsAndDeparturesForStopV2FromJSON:error:)
         completionBlock:completion
           progressBlock:progress];
}

- (id<OBAModelServiceRequest>)requestStopsForRegion:(MKCoordinateRegion)region completionBlock:(OBADataSourceCompletion)completion; {
    NSDictionary *args = @{ @"lat": @(region.center.latitude),
                            @"lon": @(region.center.longitude),
                            @"latSpan": @(region.span.latitudeDelta),
                            @"lonSpan": @(region.span.longitudeDelta) };

    return [self request:self.obaJsonDataSource
                     url:@"/api/where/stops-for-location.json"
                    args:args
                selector:@selector(getStopsV2FromJSON:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestStopsForQuery:(NSString *)stopQuery withRegion:(CLCircularRegion *)region completionBlock:(OBADataSourceCompletion)completion {
    CLLocationDistance radius = MAX(region.radius, kBigSearchRadius);
    CLLocationCoordinate2D coord = region ? region.center : [self currentOrDefaultLocationToSearch].coordinate;

    NSDictionary *args = @{@"lat": @(coord.latitude), @"lon": @(coord.longitude), @"query": stopQuery, @"radius": @(radius)};

    return [self request:self.obaJsonDataSource
                     url:@"/api/where/stops-for-location.json"
                    args:args
                selector:@selector(getStopsV2FromJSON:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestStopsForRoute:(NSString *)routeId completionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/stops-for-route/%@.json", routeId]
                    args:nil
                selector:@selector(getStopsForRouteV2FromJSON:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestStopsForPlacemark:(OBAPlacemark *)placemark completionBlock:(OBADataSourceCompletion)completion {
    MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:placemark.coordinate latRadius:kSearchRadius lonRadius:kSearchRadius];

    return [self requestStopsForRegion:region
                       completionBlock:completion];
}

- (id<OBAModelServiceRequest>)requestRoutesForQuery:(NSString *)routeQuery withRegion:(CLCircularRegion *)region completionBlock:(OBADataSourceCompletion)completion {
    CLLocationDistance radius = kBigSearchRadius;
    CLLocationCoordinate2D coord;

    if (region) {
        radius = MAX(region.radius, kBigSearchRadius);
        coord = region.center;
    }
    else {
        CLLocation *location = [self currentOrDefaultLocationToSearch];
        coord = location.coordinate;
    }

    NSDictionary *args = @{@"lat": @(coord.latitude), @"lon": @(coord.longitude), @"query": routeQuery, @"radius": @(radius)};

    return [self request:self.obaJsonDataSource
                     url:@"/api/where/routes-for-location.json"
                    args:args
                selector:@selector(getRoutesV2FromJSON:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)placemarksForAddress:(NSString *)address completionBlock:(OBADataSourceCompletion)completion {
    CLLocationCoordinate2D coord = [self currentOrDefaultLocationToSearch].coordinate;

    NSDictionary *args = @{
                           @"bounds": [NSString stringWithFormat:@"%@,%@|%@,%@", @(coord.latitude), @(coord.longitude), @(coord.latitude), @(coord.longitude)],
                           @"address": address
                           };

    return [self request:_googleMapsJsonDataSource
                     url:@"/maps/api/geocode/json"
                    args:args
                selector:@selector(getPlacemarksFromJSONObject:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestRegions:(OBADataSourceCompletion)completion {
    return [self request:self.obaRegionJsonDataSource
                     url:@"/regions-v3.json"
                    args:nil
                selector:@selector(getRegionsV2FromJson:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestAgenciesWithCoverage:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:@"/api/where/agencies-with-coverage.json"
                    args:nil
                selector:@selector(getAgenciesWithCoverageV2FromJson:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestArrivalAndDepartureForStop:(OBAArrivalAndDepartureInstanceRef *)instance completionBlock:(OBADataSourceCompletion)completion {
    OBATripInstanceRef *tripInstance = instance.tripInstance;

    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];

    args[@"tripId"] = tripInstance.tripId;
    args[@"serviceDate"] = @(tripInstance.serviceDate);

    if (tripInstance.vehicleId) {
        args[@"vehicleId"] = tripInstance.vehicleId;
    }

    if (instance.stopSequence >= 0) {
        args[@"stopSequence"] = @(instance.stopSequence);
    }

    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/arrival-and-departure-for-stop/%@.json", instance.stopId]
                    args:args
                selector:@selector(getArrivalAndDepartureForStopV2FromJSON:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestTripDetailsForTripInstance:(OBATripInstanceRef *)tripInstance completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];

    if (tripInstance.serviceDate > 0) {
        args[@"serviceDate"] = @(tripInstance.serviceDate);
    }

    if (tripInstance.vehicleId) {
        args[@"vehicleId"] = tripInstance.vehicleId;
    }

    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/trip-details/%@.json", tripInstance.tripId]
                    args:args
                selector:@selector(getTripDetailsV2FromJSON:error:)
         completionBlock:completion
           progressBlock:progress];
}

- (id<OBAModelServiceRequest>)requestVehicleForId:(NSString *)vehicleId completionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/vehicle/%@.json", vehicleId]
                    args:nil
                selector:@selector(getVehicleStatusV2FromJSON:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestShapeForId:(NSString *)shapeId completionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/shape/%@.json", shapeId]
                    args:nil
                selector:@selector(getShapeV2FromJSON:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)reportProblemWithStop:(OBAReportProblemWithStopV2 *)problem completionBlock:(OBADataSourceCompletion)completion {
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];

    args[@"stopId"] = problem.stopId;

    if (problem.code) {
        args[@"code"] = problem.code;
    }

    if (problem.userComment) {
        args[@"userComment"] = problem.userComment;
    }

    if (problem.userLocation) {
        CLLocationCoordinate2D coord = problem.userLocation.coordinate;
        args[@"userLat"] = @(coord.latitude);
        args[@"userLon"] = @(coord.longitude);
        args[@"userLocationAccuracy"] = @(problem.userLocation.horizontalAccuracy);
    }

    OBAModelServiceRequest *request = [self request:self.obaJsonDataSource
                                                url:@"/api/where/report-problem-with-stop.json"
                                               args:args
                                           selector:nil
                                    completionBlock:completion
                                      progressBlock:nil];
    request.checkCode = YES;
    return request;
}

- (id<OBAModelServiceRequest>)reportProblemWithTrip:(OBAReportProblemWithTripV2 *)problem completionBlock:(OBADataSourceCompletion)completion {
    NSString *url = [NSString stringWithFormat:@"/api/where/report-problem-with-trip.json"];

    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    OBATripInstanceRef *tripInstance = problem.tripInstance;

    args[@"tripId"] = tripInstance.tripId;
    args[@"serviceDate"] = @(tripInstance.serviceDate);

    if (tripInstance.vehicleId) {
        args[@"vehicleId"] = tripInstance.vehicleId;
    }

    if (problem.stopId) {
        args[@"stopId"] = problem.stopId;
    }

    if (problem.code) {
        args[@"code"] = problem.code;
    }

    if (problem.userComment) {
        args[@"userComment"] = problem.userComment;
    }

    args[@"userOnVehicle"] = (problem.userOnVehicle ? @"true" : @"false");

    if (problem.userVehicleNumber) {
        args[@"userVehicleNumber"] = problem.userVehicleNumber;
    }

    if (problem.userLocation) {
        CLLocationCoordinate2D coord = problem.userLocation.coordinate;
        args[@"userLat"] = @(coord.latitude);
        args[@"userLon"] = @(coord.longitude);
        args[@"userLocationAccuracy"] = @(problem.userLocation.horizontalAccuracy);
    }

    OBAModelServiceRequest *request = [self request:self.obaJsonDataSource
                                                url:url
                                               args:args
                                           selector:nil
                                    completionBlock:completion
                                      progressBlock:nil];
    request.checkCode = YES;
    return request;
}

- (OBAModelServiceRequest *)request:(OBAJsonDataSource *)source url:(NSString *)url args:(NSDictionary *)args selector:(SEL)selector completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {
    OBAModelServiceRequest *request = [self request:source selector:selector];

    request.connection = [source requestWithPath:url withArgs:args completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
        [request processData:jsonData withError:error responseCode:responseCode completionBlock:completion];
    } progressBlock:progress];
    return request;
}

- (OBAModelServiceRequest *)request:(OBAJsonDataSource *)source selector:(SEL)selector {
    OBAModelServiceRequest *request = [[OBAModelServiceRequest alloc] init];

    request.modelFactory = _modelFactory;
    request.modelFactorySelector = selector;

    if (source != _obaJsonDataSource) {
        request.checkCode = NO;
    }

    NSObject<OBABackgroundTaskExecutor> *executor = [[self class] sharedBackgroundExecutor];
    
    if (executor) {
        request.bgTask = [executor beginBackgroundTaskWithExpirationHandler:^{
            if(request.cleanupBlock) {
                request.cleanupBlock(request.bgTask);
            }
        }];
        
        [request setCleanupBlock:^(UIBackgroundTaskIdentifier identifier) {
            return [executor endBackgroundTask:identifier];
        }];
    }
    
    return request;
}

- (CLLocation *)currentOrDefaultLocationToSearch {
    CLLocation *location = _locationManager.currentLocation;

    if (!location) {
        location = _modelDao.mostRecentLocation ?: [[CLLocation alloc] initWithLatitude:47.61229680032385 longitude:-122.3386001586914];
    }

    return location;
}

#pragma mark - OBABackgroundTaskExecutor

static NSObject<OBABackgroundTaskExecutor>* executor;

+ (NSObject<OBABackgroundTaskExecutor>*)sharedBackgroundExecutor {
    return executor;
}

+ (void)addBackgroundExecutor:(NSObject<OBABackgroundTaskExecutor>*)exc {
    executor = exc;
}

@end
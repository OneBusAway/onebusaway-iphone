/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <OBAKit/OBAModelService.h>
#import <OBAKit/OBAModelServiceRequest.h>
#import <OBAKit/OBASphericalGeometryLibrary.h>
#import <OBAKit/OBAURLHelpers.h>
#import <OBAKit/OBAMacros.h>

static const CLLocationAccuracy kSearchRadius = 400;
static const CLLocationAccuracy kBigSearchRadius = 15000;

NSString * const OBAAgenciesWithCoverageAPIPath = @"/api/where/agencies-with-coverage.json";

/*
 See https://github.com/OneBusAway/onebusaway-iphone/issues/601
 for more information on this. In short, the issue is that
 the route disambiguation UI should always appears when there are
 multiple routes whose names contain the same search string, but
 sometimes this doesn't happen. It's a result of routes-for-location
 searches not having a wide enough radius.
 */
static const CLLocationAccuracy kRegionalRadius = 40000;

@implementation OBAModelService

+ (instancetype)modelServiceWithBaseURL:(NSURL*)URL {
    OBAModelService *service = [[OBAModelService alloc] init];
    OBAModelFactory *modelFactory = [OBAModelFactory modelFactory];
    service.modelFactory = modelFactory;
    service.references = modelFactory.references;
    service.obaJsonDataSource = [OBAJsonDataSource JSONDataSourceWithBaseURL:URL userID:@"test"];

    return service;
}

#pragma mark - Promise-based Requests

- (AnyPromise*)requestStopForID:(NSString*)stopID minutesBefore:(NSUInteger)minutesBefore minutesAfter:(NSUInteger)minutesAfter {
    OBAGuard(stopID.length > 0) else {
        return nil;
    }

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestStopWithArrivalsAndDeparturesForId:stopID withMinutesBefore:minutesBefore withMinutesAfter:minutesAfter completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
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

- (AnyPromise*)requestTripDetailsForTripInstance:(OBATripInstanceRef *)tripInstance {
    OBAGuard(tripInstance) else {
        return nil;
    }

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestTripDetailsForTripInstance:tripInstance completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
            if (error) {
                resolve(error);
            }
            else {
                resolve([responseData entry]);
            }
        } progressBlock:nil];
    }];
}

- (AnyPromise*)requestArrivalAndDeparture:(OBAArrivalAndDepartureInstanceRef*)instanceRef {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestArrivalAndDepartureForStop:instanceRef completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
            if (error) {
                resolve(error);
            }
            else {
                resolve([responseData entry]);
            }
        }];
    }];
}

- (AnyPromise*)requestCurrentTime {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestCurrentTimeWithCompletionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
            if (error) {
                resolve(error);
            }
            else {
                resolve(responseData[@"entry"][@"time"]);
            }
        }];
    }];
}

- (AnyPromise*)requestRegions {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestRegions:^(id responseData, NSUInteger responseCode, NSError *error) {
            resolve(error ?: [responseData values]);
        }];
    }];
}

- (AnyPromise*)requestAgenciesWithCoverage {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestAgenciesWithCoverage:^(id responseData, NSUInteger responseCode, NSError *error) {
            resolve(error ?: [responseData values]);
        }];
    }];
}

- (AnyPromise*)requestVehicleForID:(NSString*)vehicleID {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestVehicleForId:vehicleID completionBlock:^(OBAEntryWithReferencesV2 *responseData, NSUInteger responseCode, NSError *error) {
            resolve(error ?: responseData.entry);
        }];
    }];
}

#pragma mark - Old School Requests

- (id<OBAModelServiceRequest>)requestCurrentTimeWithCompletionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:@"/api/where/current-time.json"
                    args:nil
                selector:nil
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestStopWithArrivalsAndDeparturesForId:(NSString *)stopId withMinutesBefore:(NSUInteger)minutesBefore withMinutesAfter:(NSUInteger)minutesAfter completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {

    NSDictionary *args = @{ @"minutesBefore": @(minutesBefore),
                            @"minutesAfter":  @(minutesAfter) };

    NSString *escapedStopID = [self.class escapePathVariable:stopId];

    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/arrivals-and-departures-for-stop/%@.json", escapedStopID]
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
                     url:[NSString stringWithFormat:@"/api/where/stops-for-route/%@.json", [self.class escapePathVariable:routeId]]
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
        radius = MAX(region.radius, kRegionalRadius);
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
                     url:OBAAgenciesWithCoverageAPIPath
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
                     url:[NSString stringWithFormat:@"/api/where/arrival-and-departure-for-stop/%@.json", [self.class escapePathVariable:instance.stopId]]
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
                     url:[NSString stringWithFormat:@"/api/where/trip-details/%@.json", [self.class escapePathVariable:tripInstance.tripId]]
                    args:args
                selector:@selector(getTripDetailsV2FromJSON:error:)
         completionBlock:completion
           progressBlock:progress];
}

- (id<OBAModelServiceRequest>)requestVehicleForId:(NSString *)vehicleId completionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/vehicle/%@.json", [self.class escapePathVariable:vehicleId]]
                    args:nil
                selector:@selector(getVehicleStatusV2FromJSON:error:)
         completionBlock:completion
           progressBlock:nil];
}

- (id<OBAModelServiceRequest>)requestShapeForId:(NSString *)shapeId completionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/shape/%@.json", [self.class escapePathVariable:shapeId]]
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

static NSObject<OBABackgroundTaskExecutor>* sharedExecutor;

+ (NSObject<OBABackgroundTaskExecutor>*)sharedBackgroundExecutor {
    return sharedExecutor;
}

+ (void)addBackgroundExecutor:(NSObject<OBABackgroundTaskExecutor>*)exc {
    sharedExecutor = exc;
}

#pragma mark - Private Helpers

+ (NSString*)escapePathVariable:(NSString*)pathVariable {
    NSString *escaped = [pathVariable stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    // Apparently -stringByAddingPercentEncodingWithAllowedCharacters: won't remove
    // '/' characters from paths, so we get to do that manually here. Boo.
    // https://github.com/OneBusAway/onebusaway-iphone/issues/817
    return [escaped stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
}

@end

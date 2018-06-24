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
#import <OBAKit/OBASphericalGeometryLibrary.h>
#import <OBAKit/OBASearchResult.h>
#import <OBAKit/OBARegionalAlert.h>

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
    OBAModelService *service = [[self.class alloc] init];
    OBAModelFactory *modelFactory = [OBAModelFactory modelFactory];
    service.modelFactory = modelFactory;
    service.references = modelFactory.references;
    service.obaJsonDataSource = [OBAJsonDataSource JSONDataSourceWithBaseURL:URL userID:@"test"];

    return service;
}

#pragma mark - Promise-based Requests

- (AnyPromise*)requestArrivalAndDeparture:(OBAArrivalAndDepartureInstanceRef*)instanceRef {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestArrivalAndDepartureForStop:instanceRef completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: [responseData entry]);
        }];
    }];
}

- (AnyPromise*)requestArrivalAndDepartureWithConvertible:(id<OBAArrivalAndDepartureConvertible>)convertible {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestArrivalAndDepartureForStopID:[convertible stopID] tripID:[convertible tripID] serviceDate:[convertible serviceDate] vehicleID:[convertible vehicleID] stopSequence:[convertible stopSequence] completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: [responseData entry]);
        }];
    }];
}

- (AnyPromise*)requestCurrentTime {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestCurrentTimeWithCompletionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: responseData[@"entry"][@"time"]);
        }];
    }];
}

- (AnyPromise*)requestAgenciesWithCoverage {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestAgenciesWithCoverage:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: [responseData values]);
        }];
    }];
}

- (AnyPromise*)requestVehicleForID:(NSString*)vehicleID {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestVehicleForId:vehicleID completionBlock:^(OBAEntryWithReferencesV2 *responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: responseData.entry);
        }];
    }];
}

- (AnyPromise*)requestStopsNear:(CLLocationCoordinate2D)coordinate {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestStopsForCoordinate:coordinate completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            OBASearchResult *searchResult = [OBASearchResult resultFromList:responseData];
            searchResult.searchType = OBASearchTypeStops;
            resolve(error ?: searchResult);
        }];
    }];
}

- (AnyPromise*)requestShapeForID:(NSString*)shapeID {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestShapeForId:shapeID completionBlock:^(NSString *polylineString, NSHTTPURLResponse *response, NSError *error) {
            if (polylineString) {
                resolve([OBASphericalGeometryLibrary decodePolylineStringAsMKPolyline:polylineString]);
            }
            else {
                resolve(error);
            }
        }];
    }];
}

#pragma mark - Old School Requests

- (OBAModelServiceRequest*)requestCurrentTimeWithCompletionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:@"/api/where/current-time.json"
                    args:nil
                selector:nil
         completionBlock:completion];
}

- (AnyPromise*)requestStopsForRegion:(MKCoordinateRegion)region {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestStopsForRegion:region completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: [OBASearchResult resultFromList:responseData]);
        }];
    }];
}

- (OBAModelServiceRequest*)requestStopsForRegion:(MKCoordinateRegion)region completionBlock:(OBADataSourceCompletion)completion {
    NSDictionary *args = @{ @"lat": @(region.center.latitude),
                            @"lon": @(region.center.longitude),
                            @"latSpan": @(region.span.latitudeDelta),
                            @"lonSpan": @(region.span.longitudeDelta) };

    return [self request:self.obaJsonDataSource
                     url:@"/api/where/stops-for-location.json"
                    args:args
                selector:@selector(getStopsV2FromJSON:error:)
         completionBlock:completion];
}

- (OBAModelServiceRequest*)requestStopsForCoordinate:(CLLocationCoordinate2D)coordinate
                                        completionBlock:(OBADataSourceCompletion)completion {
    NSDictionary *args = @{ @"lat": @(coordinate.latitude),
                            @"lon": @(coordinate.longitude) };

    return [self request:self.obaJsonDataSource
                     url:@"/api/where/stops-for-location.json"
                    args:args
                selector:@selector(getStopsV2FromJSON:error:)
         completionBlock:completion];
}

- (AnyPromise*)requestStopsForQuery:(NSString*)query region:(nullable CLCircularRegion*)region {
    OBAGuardClass(query, NSString) else {
        return nil;
    }
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestStopsForQuery:query withRegion:region completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: [OBASearchResult resultFromList:responseData]);
        }];
    }];
}

- (OBAModelServiceRequest*)requestStopsForQuery:(NSString *)stopQuery withRegion:(CLCircularRegion *)region completionBlock:(OBADataSourceCompletion)completion {
    CLLocationDistance radius = MAX(region.radius, kBigSearchRadius);
    CLLocationCoordinate2D coord = region ? region.center : [self currentOrDefaultLocationToSearch].coordinate;

    NSDictionary *args = @{@"lat": @(coord.latitude), @"lon": @(coord.longitude), @"query": stopQuery, @"radius": @(radius)};

    return [self request:self.obaJsonDataSource
                     url:@"/api/where/stops-for-location.json"
                    args:args
                selector:@selector(getStopsV2FromJSON:error:)
         completionBlock:completion];
}

#pragma mark - Stops for Route

- (AnyPromise*)requestStopsForRoute:(NSString*)routeID {
    OBAGuardClass(routeID, NSString) else {
        return nil;
    }
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestStopsForRoute:routeID completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: responseData);
        }];
    }];
}

- (OBAModelServiceRequest*)requestStopsForRoute:(NSString *)routeId completionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/stops-for-route/%@.json", [OBAURLHelpers escapePathVariable:routeId]]
                    args:nil
                selector:@selector(getStopsForRouteV2FromJSON:error:)
         completionBlock:completion];
}

- (AnyPromise*)requestStopsForPlacemark:(OBAPlacemark*)placemark {
    OBAGuardClass(placemark, OBAPlacemark) else {
        return nil;
    }
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestStopsForPlacemark:placemark completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: [OBASearchResult resultFromList:responseData]);
        }];
    }];
}

- (OBAModelServiceRequest*)requestStopsForPlacemark:(OBAPlacemark *)placemark completionBlock:(OBADataSourceCompletion)completion {
    MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:placemark.coordinate latRadius:kSearchRadius lonRadius:kSearchRadius];

    return [self requestStopsForRegion:region completionBlock:completion];
}

- (AnyPromise*)requestRoutesForQuery:(NSString*)routeQuery region:(CLCircularRegion*)region {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestRoutesForQuery:routeQuery withRegion:region completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
            resolve(error ?: [OBASearchResult resultFromList:responseData]);
        }];
    }];
}

- (OBAModelServiceRequest*)requestRoutesForQuery:(NSString *)routeQuery withRegion:(CLCircularRegion *)region completionBlock:(OBADataSourceCompletion)completion {
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
         completionBlock:completion];
}

#pragma mark - Placemarks

- (AnyPromise*)placemarksForAddress:(NSString*)address {
    OBAGuardClass(address, NSString) else {
        return nil;
    }

    CLLocationCoordinate2D coord = [self currentOrDefaultLocationToSearch].coordinate;
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = address;
    request.region = MKCoordinateRegionMakeWithDistance(coord, 10000, 10000); // todo: reconsider this size of region.
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
            if (error) {
                resolve(error);
                return;
            }

            NSMutableArray<OBAPlacemark*> *placemarks = [[NSMutableArray alloc] init];
            for (MKMapItem *mapItem in response.mapItems) {
                OBAPlacemark *placemark = [[OBAPlacemark alloc] initWithMapItem:mapItem];
                [placemarks addObject:placemark];
            }

            resolve([NSArray arrayWithArray:placemarks]);
        }];
    }];
}

- (OBAModelServiceRequest*)requestAgenciesWithCoverage:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:OBAAgenciesWithCoverageAPIPath
                    args:nil
                selector:@selector(getAgenciesWithCoverageV2FromJson:error:)
         completionBlock:completion];
}

- (OBAModelServiceRequest*)requestArrivalAndDepartureForStop:(OBAArrivalAndDepartureInstanceRef *)instance completionBlock:(OBADataSourceCompletion)completion {
    OBATripInstanceRef *tripInstance = instance.tripInstance;

    return [self requestArrivalAndDepartureForStopID:instance.stopId tripID:tripInstance.tripId serviceDate:tripInstance.serviceDate vehicleID:tripInstance.vehicleId stopSequence:instance.stopSequence completionBlock:completion];
}

- (OBAModelServiceRequest*)requestArrivalAndDepartureForStopID:(NSString*)stopID
                                                           tripID:(NSString*)tripID
                                                      serviceDate:(long long)serviceDate
                                                        vehicleID:(nullable NSString*)vehicleID
                                                     stopSequence:(NSInteger)stopSequence
                                                completionBlock:(OBADataSourceCompletion)completion {

    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];

    args[@"tripId"] = tripID;
    args[@"serviceDate"] = @(serviceDate);

    if (vehicleID) {
        args[@"vehicleId"] = vehicleID;
    }

    if (stopSequence >= 0) {
        args[@"stopSequence"] = @(stopSequence);
    }

    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/arrival-and-departure-for-stop/%@.json", [OBAURLHelpers escapePathVariable:stopID]]
                    args:args
                selector:@selector(getArrivalAndDepartureForStopV2FromJSON:error:)
         completionBlock:completion];
}

- (OBAModelServiceRequest*)requestVehicleForId:(NSString *)vehicleId completionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/vehicle/%@.json", [OBAURLHelpers escapePathVariable:vehicleId]]
                    args:nil
                selector:@selector(getVehicleStatusV2FromJSON:error:)
         completionBlock:completion];
}

- (OBAModelServiceRequest*)requestShapeForId:(NSString *)shapeId completionBlock:(OBADataSourceCompletion)completion {
    return [self request:self.obaJsonDataSource
                     url:[NSString stringWithFormat:@"/api/where/shape/%@.json", [OBAURLHelpers escapePathVariable:shapeId]]
                    args:nil
                selector:@selector(getShapeV2FromJSON:error:)
         completionBlock:completion];
}

- (OBAModelServiceRequest*)reportProblemWithStop:(OBAReportProblemWithStopV2 *)problem completionBlock:(OBADataSourceCompletion)completion {
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
                                    completionBlock:completion];
    request.checkCode = YES;
    return request;
}

- (OBAModelServiceRequest*)reportProblemWithTrip:(OBAReportProblemWithTripV2 *)problem completionBlock:(OBADataSourceCompletion)completion {
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
                                    completionBlock:completion];
    request.checkCode = YES;
    return request;
}

- (OBAModelServiceRequest *)request:(OBAJsonDataSource *)source url:(NSString *)url args:(NSDictionary *)args selector:(SEL)selector completionBlock:(OBADataSourceCompletion)completion {
    return [self request:source url:url HTTPMethod:@"GET" queryParams:args formBody:nil selector:selector completionBlock:completion];
}

// this method is weird. it creates the modelservice request object, stuffs a reference to the model factory into it,
// specifies the model factory selector to use to process data on completion, then asks the OBAJSONDataSource for an
// url session data task (which is already initiated by the time the `request.urlSessionTask` property is set).
// When the url session task completes, it calls into its parent object (the request) to execute the -processData
// method. I wonder if this is causing a memory leak. Also, the flow of control is just weird.
- (OBAModelServiceRequest *)request:(OBAJsonDataSource *)source url:(NSString *)url HTTPMethod:(NSString*)HTTPMethod queryParams:(NSDictionary *)queryParams formBody:(NSDictionary *)formBody selector:(SEL)selector completionBlock:(OBADataSourceCompletion)completion {

    OBAModelServiceRequest *request = [[OBAModelServiceRequest alloc] init];
    request.modelFactory = self.modelFactory;
    request.modelFactorySelector = selector;
    request.checkCode = source.checkStatusCodeInBody;

    request.urlSessionTask = [source requestWithPath:url HTTPMethod:HTTPMethod queryParameters:queryParams formBody:formBody completionBlock:^(id jsonData, NSHTTPURLResponse *response, NSError *error) {
        [request processData:jsonData withError:error response:response completionBlock:completion];
    }];

    return request;
}

- (CLLocation *)currentOrDefaultLocationToSearch {
    CLLocation *location = _locationManager.currentLocation;

    if (!location) {
        location = _modelDao.mostRecentLocation ?: [[CLLocation alloc] initWithLatitude:47.61229680032385 longitude:-122.3386001586914];
    }

    return location;
}

@end

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

#import <OBAKit/OBAModelDAO.h>
#import <OBAKit/OBAModelServiceRequest.h>
#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAJsonDataSource.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBAPlacemark.h>
#import <OBAKit/OBATripInstanceRef.h>
#import <OBAKit/OBAArrivalAndDepartureInstanceRef.h>
#import <OBAKit/OBAReportProblemWithStopV2.h>
#import <OBAKit/OBAReportProblemWithTripV2.h>
#import <OBAKit/OBALocationManager.h>
#import <OBAKit/OBAArrivalAndDepartureConvertible.h>

@import PromiseKit;
@import MapKit;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBAAgenciesWithCoverageAPIPath;

@interface OBAModelService : NSObject
@property(nonatomic, strong, readonly) OBAModelDAO *modelDAO;
@property(nonatomic, strong, readonly) OBAModelFactory *modelFactory;
@property(nonatomic, strong, readonly) OBAJsonDataSource *obaJsonDataSource;
@property(nonatomic, strong, readonly) OBAJsonDataSource *obacoJsonDataSource;
@property(nonatomic, strong, readonly) OBAJsonDataSource *unparsedDataSource;

/**
 Convenience method for constructing an entire
 model service/factory/references stack.
 */
+ (instancetype)modelServiceWithBaseURL:(NSURL*)URL;

- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO references:(OBAReferencesV2*)references locationManager:(OBALocationManager*)locationManager;

/**
 Cancels all open network requests.
 */
- (void)cancelOpenConnections;

#pragma mark - OBAArrivalAndDepartureInstanceRef -> OBAArrivalAndDepartureV2

/**
 Retrieves an up-to-date OBAArrivalAndDepartureV2 object.

 @param instanceRef The OBAArrivalAndDepartureInstanceRef whose parent object we're updating (I think? The model architecture is still confusing to me.)

 @return A promise that resolves to a OBAArrivalAndDepartureV2 object.
 */
- (AnyPromise*)requestArrivalAndDeparture:(OBAArrivalAndDepartureInstanceRef*)instanceRef;

#pragma mark - OBAArrivalAndDepartureConvertible -> OBAArrivalAndDepartureV2

/**
 Retrieves an OBAArrivalAndDepartureV2 object from the server given a trip deep link object.

 @param convertible An object that contains properties that can be used to retrieve an OBAArrivalAndDepartureV2 object.
 @return A promise that resolves to an OBAArrivalAndDepartureV2 object
 */
- (AnyPromise*)requestArrivalAndDepartureWithConvertible:(id<OBAArrivalAndDepartureConvertible>)convertible;

#pragma mark - Vehicle ID -> OBAVehicleStatusV2

/**
 Retrieves the OBAVehicleStatusV2 object for the specified vehicleID.

 @param vehicleID The ID for the vehicle to retrieve.

 @return A promise that that resolves to OBAVehicleStatusV2
 */
- (AnyPromise*)requestVehicleForID:(NSString*)vehicleID;

#pragma mark - CLLocationCoordinate2D -> [OBAStopV2]

/**
 Retrieves the stops near the specified coordiante

 @param coordinate     Center coordinate for retrieving stops

 @return A promise that resolves to an OBASearchResult object
 */
- (AnyPromise*)requestStopsNear:(CLLocationCoordinate2D)coordinate;


#pragma mark - Shape ID -> MKPolyline

/**
 Retrives the shape identified by the specified shape ID.

 @param shapeID Identifier of a shape
 @return A promise that resolves to an MKPolyline object.
 */
- (AnyPromise*)requestShapeForID:(NSString*)shapeID;

/**
 *  Makes an asynchronous request to fetch a shape
 *
 *  @param shapeId    Identifier of a shape
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestShapeForId:(NSString *)shapeId
                                completionBlock:(OBADataSourceCompletion)completion;

#pragma mark - Current Time

/**
 Retrieves the current server time as an NSNumber representing the number of milliseconds since January 1, 1970.

 @return A promise that resolves to an NSNumber object.
 */
- (AnyPromise*)requestCurrentTime;

/**
 Makes an asynchronous request for a set of stops within a given region

 @param region Region for which the stops are returned
 @return A promise that resolves to an OBASearchResult object
 */
- (AnyPromise*)requestStopsForRegion:(MKCoordinateRegion)region;

/**
 Makes an asynchronous request to get a set of stops for a given query, bounded by a region

 @param query A "stopCode" represented by a string
 @param region A circular region
 @return Resolves to an OBASearchResult object
 */
- (AnyPromise*)requestStopsForQuery:(NSString*)query region:(nullable CLCircularRegion*)region;

/**
 Requests the list of stops for the specified route ID.

 @param routeID Identifier of a route for which the stops need to be fetched
 @return A promise that resolves to an OBAStopsForRouteV2 object.
 */
- (AnyPromise*)requestStopsForRoute:(NSString*)routeID;

/**
 Fetches a set of stops near a placemark

 @param placemark A placemark defined by @see OBAPlacemark object
 @return An @see AnyPromise object that resolves to an OBASearchResult
 */
- (AnyPromise*)requestStopsForPlacemark:(OBAPlacemark*)placemark;

/**
 Fetches a set of routes

 @param routeQuery Query that identifies desired routes
 @param region The geographic region to which the search is limited
 @return A promise that resolves to an instance of OBAListWithRangeAndReferencesV2
 */
- (AnyPromise*)requestRoutesForQuery:(NSString*)routeQuery region:(CLCircularRegion*)region;

#pragma mark - Address -> [OBAPlacemark]

/**
 Returns a collection of placemarks for the given address

 @param address A string that corresponds to a location
 @return A promise that resolves to an array of OBAPlacemark objects
 */
- (AnyPromise*)placemarksForAddress:(NSString*)address;

#pragma mark - Problem Reporting

/**
 *  Makes an asynchronous request to report a problem with a stop
 *
 *  @param problem    Problem definition to be used for submission
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)reportProblemWithStop:(OBAReportProblemWithStopV2 *)problem
                                    completionBlock:(OBADataSourceCompletion)completion;
/**
 *  Makes an asynchronous request to report a problem with a trip
 *
 *  @param problem    Problem definition to be used for submission
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)reportProblemWithTrip:(OBAReportProblemWithTripV2 *)problem
                                    completionBlock:(OBADataSourceCompletion)completion;

@end

NS_ASSUME_NONNULL_END

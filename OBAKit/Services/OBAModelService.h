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
#import <OBAKit/OBAAlarm.h>

@import PromiseKit;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBAAgenciesWithCoverageAPIPath;

/**
 * This protocol mimics the functionality of UIApplication.  It is placed here to get around Extension only API limitation.
 */
@protocol OBABackgroundTaskExecutor <NSObject>
- (UIBackgroundTaskIdentifier) beginBackgroundTaskWithExpirationHandler:(void(^)(void))handler;
- (UIBackgroundTaskIdentifier) endBackgroundTask:(UIBackgroundTaskIdentifier) task;
@end

@interface OBAModelService : NSObject
@property (nonatomic, strong) OBAReferencesV2 *references;
@property (nonatomic, strong) OBAModelDAO *modelDao;
@property (nonatomic, strong) OBAModelFactory *modelFactory;
@property (nonatomic, strong) OBAJsonDataSource *obaJsonDataSource;
@property (nonatomic, strong) OBAJsonDataSource *obaRegionJsonDataSource;
@property (nonatomic, strong) OBAJsonDataSource *googleMapsJsonDataSource;
@property (nonatomic, strong) OBAJsonDataSource *obacoJsonDataSource;
@property (nonatomic, strong) OBALocationManager *locationManager;

/**
 Convenience method for constructing an entire
 model service/factory/references stack.
 */
+ (instancetype)modelServiceWithBaseURL:(NSURL*)URL;

/**
 * Registers a background executor to be used by all services. This method should not be used by extensions.
 */
+ (void)addBackgroundExecutor:(NSObject<OBABackgroundTaskExecutor>*) executor;

#pragma mark - Regional Alerts

/**
 Retrieves a list of alert messages for the specified `region` since `date`. The completion block's responseData is [OBARegionalAlert]

 @param region The region from which alerts are desired.
 @param date The last date that alerts were requested. Specify nil for all time.
 @param completion Completion block is called when the operation finishes, regardless of success or failure.
 @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestRegionalAlerts:(OBARegionV2*)region sinceDate:(nullable NSDate*)date completionBlock:(OBADataSourceCompletion)completion;

#pragma mark - Alarms

- (nullable OBAModelServiceRequest*)requestAlarm:(OBAAlarm*)alarm userPushNotificationID:(NSString*)userPushNotificationID completionBlock:(OBADataSourceCompletion)completion;

- (AnyPromise*)requestAlarm:(OBAAlarm*)alarm userPushNotificationID:(NSString*)userPushNotificationID;

#pragma mark - Stop ID -> ArrivalsAndDeparturesV2

/**
 Stop data with arrivals and departures for the specified stopID.

 @param stopID        The ID of the stop that will be returned.
 @param minutesBefore How many minutes of elapsed departures should be included.
 @param minutesAfter  How many minutes into the future should be returned.

 @return A promise that resolves to an OBAArrivalsAndDeparturesForStopV2 object
 */
- (AnyPromise*)requestStopForID:(NSString*)stopID minutesBefore:(NSUInteger)minutesBefore minutesAfter:(NSUInteger)minutesAfter;

/**
 *  Makes an asynchronous request to fetch a stop object that is also inflated with additional data for arrival and departure time
 *
 *  @param stopId        The string identifier of the stop to be fetched
 *  @param minutesBefore The lower bound of time for which arrivals are returned
 *  @param minutesAfter  The upper bound of time for which arrivals are returned
 *  @param completion    The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestStopWithArrivalsAndDeparturesForId:(NSString *)stopId
                                                      withMinutesBefore:(NSUInteger)minutesBefore
                                                       withMinutesAfter:(NSUInteger)minutesAfter
                                                        completionBlock:(OBADataSourceCompletion)completion;

#pragma mark - OBATripInstanceRef -> OBATripDetailsV2

/**
 Trip details for the specified OBATripInstanceRef

 @param tripInstance The trip instance reference

 @return An instance of OBATripDetailsV2
 */
- (AnyPromise*)requestTripDetailsForTripInstance:(OBATripInstanceRef *)tripInstance;

/**
 *  Makes an asynchronous request to fetch trip details
 *
 *  @param tripInstance An intance of a trip
 *  @param completion   The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestTripDetailsForTripInstance:(OBATripInstanceRef *)tripInstance
                                                completionBlock:(OBADataSourceCompletion)completion;

#pragma mark - OBAArrivalAndDepartureInstanceRef -> OBAArrivalAndDepartureV2

/**
 Retrieves an up-to-date OBAArrivalAndDepartureV2 object.

 @param instanceRef The OBAArrivalAndDepartureInstanceRef whose parent object we're updating (I think? The model architecture is still confusing to me.)

 @return A promise that resolves to a OBAArrivalAndDepartureV2 object.
 */
- (AnyPromise*)requestArrivalAndDeparture:(OBAArrivalAndDepartureInstanceRef*)instanceRef;

/**
 *  Makes an asynchronous request to fetch arrival and departure times for a particular stop
 *
 *  @param instance   An instance of a stop
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestArrivalAndDepartureForStop:(OBAArrivalAndDepartureInstanceRef *)instance
                                                completionBlock:(OBADataSourceCompletion)completion;

#pragma mark - OBAArrivalAndDepartureConvertible -> OBAArrivalAndDepartureV2

/**
 Retrieves an OBAArrivalAndDepartureV2 object from the server given a trip deep link object.

 @param convertible An object that contains properties that can be used to retrieve an OBAArrivalAndDepartureV2 object.
 @return A promise that resolves to an OBAArrivalAndDepartureV2 object
 */
- (AnyPromise*)requestArrivalAndDepartureWithConvertible:(id<OBAArrivalAndDepartureConvertible>)convertible;

#pragma mark - Regions

/**
 Retrieves all available OBA regions, including experimental and inactive regions. Returns an array of OBARegionV2 objects.
 *
 *  @return A promise that resolves to NSArray<OBARegionV2*>*.
 */
- (AnyPromise*)requestRegions;

/**
 *  Makes an asynchronous request to fetch all available OBA regions, including experimental and inactive
 *
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestRegions:(OBADataSourceCompletion)completion;

#pragma mark - Agencies

/**
 Retrieves all available OBA regions, including experimental and inactive regions. Returns an array of OBARegionV2 objects.
 *
 *  @return A promise that resolves to NSArray<OBAAgencyWithCoverageV2*>*.
 */
- (AnyPromise*)requestAgenciesWithCoverage;

/**
 *  Makes an asynchronous request to fetch all available agencies.
 *
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestAgenciesWithCoverage:(OBADataSourceCompletion)completion;

#pragma mark - Vehicle ID -> OBAVehicleStatusV2

/**
 Retrieves the OBAVehicleStatusV2 object for the specified vehicleID.

 @param vehicleID The ID for the vehicle to retrieve.

 @return A promise that that resolves to OBAVehicleStatusV2
 */
- (AnyPromise*)requestVehicleForID:(NSString*)vehicleID;

/**
 *  Makes an asynchronous request to fetch a vehicle definition based on id
 *
 *  @param vehicleId  The identifier of the vehicle to be fetched
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestVehicleForId:(NSString *)vehicleId
                                  completionBlock:(OBADataSourceCompletion)completion;

#pragma mark - CLLocationCoordinate2D -> [OBAStopV2]

/**
 Retrieves the stops near the specified coordiante

 @param coordinate     Center coordinate for retrieving stops

 @return A promise that resolves to an OBASearchResult object
 */
- (AnyPromise*)requestStopsNear:(CLLocationCoordinate2D)coordinate;

/**
 *  Makes an asynchronous request for a set of stops near the given coordinate
 *
 *  @param coordinate     Coordinate for which the stops are returned
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestStopsForCoordinate:(CLLocationCoordinate2D)coordinate
                                        completionBlock:(OBADataSourceCompletion)completion;

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
 *  Makes an asynchronous request to fetch the current server time.
 *
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestCurrentTimeWithCompletionBlock:(OBADataSourceCompletion)completion;

#pragma mark - Requests for [OBAStopV2]

/**
 Makes an asynchronous request for a set of stops within a given region

 @param region Region for which the stops are returned
 @return A promise that resolves to an OBASearchResult object
 */
- (AnyPromise*)requestStopsForRegion:(MKCoordinateRegion)region;

/**
 *  Makes an asynchronous request for a set of stops within a given region
 *
 *  @param region     Region for which the stops are returned
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestStopsForRegion:(MKCoordinateRegion)region
                                    completionBlock:(OBADataSourceCompletion)completion;

/**
 Makes an asynchronous request to get a set of stops for a given query, bounded by a region

 @param query A "stopCode" represented by a string
 @param region A circular region
 @return Resolves to an OBASearchResult object
 */
- (AnyPromise*)requestStopsForQuery:(NSString*)query region:(nullable CLCircularRegion*)region;

/**
 *  Makes an asynchronous request to get a set of stops for a given query, bounded by a region
 *
 *  @param stopQuery  A "stopCode" represented by a string
 *  @param region     A region
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestStopsForQuery:(NSString *)stopQuery
                                        withRegion:(nullable CLCircularRegion *)region
                                   completionBlock:(OBADataSourceCompletion)completion;


/**
 Requests the list of stops for the specified route ID.

 @param routeID Identifier of a route for which the stops need to be fetched
 @return A promise that resolves to an OBAStopsForRouteV2 object.
 */
- (AnyPromise*)requestStopsForRoute:(NSString*)routeID;

/**
 *  Makes an asynchronous request to fetch a set of stops that belong to a particular route.
 *
 *  @param routeId    Identifier of a route for which the stops need to be fetched
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestStopsForRoute:(NSString *)routeId
                                   completionBlock:(OBADataSourceCompletion)completion;

/**
 Fetches a set of stops near a placemark

 @param placemark A placemark defined by @see OBAPlacemark object
 @return An @see AnyPromise object that resolves to an OBASearchResult
 */
- (AnyPromise*)requestStopsForPlacemark:(OBAPlacemark*)placemark;

/**
 *  Makes an asynchronous request to fetch a set of stops near a placemark
 *
 *  @param placemark  A placemark defined by @see OBAPlacemark object
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestStopsForPlacemark:(OBAPlacemark *)placemark
                                       completionBlock:(OBADataSourceCompletion)completion;

/**
 Fetches a set of routes

 @param routeQuery Query that identifies desired routes
 @param region The geographic region to which the search is limited
 @return A promise that resolves to an instance of OBAListWithRangeAndReferencesV2
 */
- (AnyPromise*)requestRoutesForQuery:(NSString*)routeQuery region:(CLCircularRegion*)region;

/**
 *  Makes an asynchronous request to fetch a set of routes
 *
 *  @param routeQuery Query to identify a route
 *  @param region     The region by which the search is going to be limited by
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)requestRoutesForQuery:(NSString *)routeQuery
                                         withRegion:(nullable CLCircularRegion *)region
                                    completionBlock:(OBADataSourceCompletion)completion;

#pragma mark - Address -> [OBAPlacemark]

/**
 Returns a collection of placemarks for the given address

 @param address A string that corresponds to a location
 @return A promise that resolves to an array of OBAPlacemark objects
 */
- (AnyPromise*)placemarksForAddress:(NSString*)address;

/**
 *  Makes an asynchronous request to fetch a set of placemarks based on address string
 *
 *  @param address    The address to be used to search for placemarks
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (OBAModelServiceRequest*)placemarksForAddress:(NSString *)address
                                   completionBlock:(OBADataSourceCompletion)completion;

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

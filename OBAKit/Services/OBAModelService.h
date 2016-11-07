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
#import <OBAKit/OBATripDeepLink.h>

@import PromiseKit;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBAAgenciesWithCoverageAPIPath;

@protocol OBAModelServiceRequest <NSObject>
- (void)cancel;
@end

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
@property (nonatomic, strong) OBAJsonDataSource *googlePlacesJsonDataSource;
@property (nonatomic, strong) OBALocationManager *locationManager;

/**
 Convenience method for constructing an entire
 model service/factory/references stack.
 */
+ (instancetype)modelServiceWithBaseURL:(NSURL*)URL;

/**
 * Registers a background executor to be used by all services.  This method should not be used by extensions.
 */
+(void) addBackgroundExecutor:(NSObject<OBABackgroundTaskExecutor>*) executor;

/**
 Stop data with arrivals and departures for the specified stopID.

 @param stopID        The ID of the stop that will be returned.
 @param minutesBefore How many minutes of elapsed departures should be included.
 @param minutesAfter  How many minutes into the future should be returned.

 @return A promise that resolves to an OBAArrivalsAndDeparturesForStopV2 object
 */
- (AnyPromise*)requestStopForID:(NSString*)stopID minutesBefore:(NSUInteger)minutesBefore minutesAfter:(NSUInteger)minutesAfter;

/**
 Trip details for the specified OBATripInstanceRef

 @param tripInstance The trip instance reference

 @return An instance of OBATripDetailsV2
 */
- (AnyPromise*)requestTripDetailsForTripInstance:(OBATripInstanceRef *)tripInstance;

/**
 Retrieves an up-to-date OBAArrivalAndDepartureV2 object.

 @param instanceRef The OBAArrivalAndDepartureInstanceRef whose parent object we're updating (I think? The model architecture is still confusing to me.)

 @return A promise that resolves to a OBAArrivalAndDepartureV2 object.
 */
- (AnyPromise*)requestArrivalAndDeparture:(OBAArrivalAndDepartureInstanceRef*)instanceRef;

/**
 Retrieves an OBAArrivalAndDepartureV2 object from the server given a trip deep link object.

 @param tripDeepLink A trip deep link object
 @return A promise that resolves to an OBAArrivalAndDepartureV2 object
 */
- (AnyPromise*)requestArrivalAndDepartureWithTripDeepLink:(OBATripDeepLink*)tripDeepLink;

/**
 Retrieves the current server time as an NSNumber representing the number of milliseconds since January 1, 1970.

 @return A promise that resolves to an NSNumber object.
 */
- (AnyPromise*)requestCurrentTime;

/**
 Retrieves all available OBA regions, including experimental and inactive regions. Returns an array of OBARegionV2 objects.
 *
 *  @return A promise that resolves to NSArray<OBARegionV2*>*.
 */
- (AnyPromise*)requestRegions;

/**
 Retrieves all available OBA regions, including experimental and inactive regions. Returns an array of OBARegionV2 objects.
 *
 *  @return A promise that resolves to NSArray<OBAAgencyWithCoverageV2*>*.
 */
- (AnyPromise*)requestAgenciesWithCoverage;

/**
 Retrieves the OBAVehicleStatusV2 object for the specified vehicleID.

 @param vehicleID The ID for the vehicle to retrieve.

 @return A promise that that resolves to OBAVehicleStatusV2
 */
- (AnyPromise*)requestVehicleForID:(NSString*)vehicleID;

/**
   Retrieves the stops near the specified coordiante
 
   @param coordinate     Center coordinate for retrieving stops

   @return A promise that resolves to NSArray<OBAStopV2*>*
 */
- (AnyPromise*)requestStopsNear:(CLLocationCoordinate2D)coordinate;

/**
 *  Makes an asynchronous request to fetch the current server time.
 *
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestCurrentTimeWithCompletionBlock:(OBADataSourceCompletion)completion;

/**
 *  Makes an asynchronous request to fetch a stop object that is also inflated with additional data for arrival and departure time
 *
 *  @param stopId        The string identifier of the stop to be fetched
 *  @param minutesBefore The lower bound of time for which arrivals are returned
 *  @param minutesAfter  The upper bound of time for which arrivals are returned
 *  @param completion    The block to be called once the request completes, this is always executed on the main thread.
 *  @param progress      The block to be called with progress updates, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestStopWithArrivalsAndDeparturesForId:(NSString *)stopId
                                                      withMinutesBefore:(NSUInteger)minutesBefore
                                                       withMinutesAfter:(NSUInteger)minutesAfter
                                                        completionBlock:(OBADataSourceCompletion)completion
                                                          progressBlock:(nullable OBADataSourceProgress)progress;
/**
 *  Makes an asynchronous request for a set of stops within a given region
 *
 *  @param region     Region for which the stops are returned
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestStopsForRegion:(MKCoordinateRegion)region
                                    completionBlock:(OBADataSourceCompletion)completion;

/**
 *  Makes an asynchronous request for a set of stops near the given coordinate
 *
 *  @param coordinate     Coordinate for which the stops are returned
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestStopsForCoordinate:(CLLocationCoordinate2D)coordinate
                                        completionBlock:(OBADataSourceCompletion)completion;

/**
 *  Makes an asynchronous request to get a set of stops for a given query, bounded by a region
 *
 *  @param stopQuery  A "stopCode" represented by a string
 *  @param region     A region
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestStopsForQuery:(NSString *)stopQuery
                                        withRegion:(nullable CLCircularRegion *)region
                                   completionBlock:(OBADataSourceCompletion)completion;
/**
 *  Makes an asynchronous request to fetch a set of stops that belong to a particular route.
 *
 *  @param routeId    Identifier of a route for which the stops need to be fetched
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestStopsForRoute:(NSString *)routeId
                                   completionBlock:(OBADataSourceCompletion)completion;
/**
 *  Makes an asynchronous request to fetch a set of stops near a placemark
 *
 *  @param placemark  A placemark defined by @see OBAPlacemark object
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestStopsForPlacemark:(OBAPlacemark *)placemark
                                       completionBlock:(OBADataSourceCompletion)completion;

/**
 *  Makes an asynchronous request to fetch a set of routes
 *
 *  @param routeQuery Query to identify a route
 *  @param region     The region by which the search is going to be limited by
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestRoutesForQuery:(NSString *)routeQuery
                                         withRegion:(nullable CLCircularRegion *)region
                                    completionBlock:(OBADataSourceCompletion)completion;
/**
 *  Makes an asynchronous request to fetch a set of placemarks based on address string
 *
 *  @param address    The address to be used to search for placemarks
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)placemarksForAddress:(NSString *)address
                                   completionBlock:(OBADataSourceCompletion)completion;

/**
 *  Makes an asynchronous request to fetch all available OBA regions, including experimental and inactive
 *
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestRegions:(OBADataSourceCompletion)completion;

/**
 *  Makes an asynchronous request to fetch all available agencies.
 *
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestAgenciesWithCoverage:(OBADataSourceCompletion)completion;

/**
 *  Makes an asynchronous request to fetch arrival and departure times for a particular stop
 *
 *  @param instance   An instance of a stop
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestArrivalAndDepartureForStop:(OBAArrivalAndDepartureInstanceRef *)instance
                                                completionBlock:(OBADataSourceCompletion)completion;
/**
 *  Makes an asynchronous request to fetch trip details
 *
 *  @param tripInstance An intance of a trip
 *  @param completion   The block to be called once the request completes, this is always executed on the main thread.
 *  @param progress     The block to be called with progress updates, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestTripDetailsForTripInstance:(OBATripInstanceRef *)tripInstance
                                                completionBlock:(OBADataSourceCompletion)completion
                                                  progressBlock:(nullable OBADataSourceProgress)progress;
/**
 *  Makes an asynchronous request to fetch a vehicle definition based on id
 *
 *  @param vehicleId  The identifier of the vehicle to be fetched
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestVehicleForId:(NSString *)vehicleId
                                  completionBlock:(OBADataSourceCompletion)completion;
/**
 *  Makes an asynchronous request to fetch a shape
 *
 *  @param shapeId    Identifier of a shape
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)requestShapeForId:(NSString *)shapeId
                                completionBlock:(OBADataSourceCompletion)completion;
/**
 *  Makes an asynchronous request to report a problem with a stop
 *
 *  @param problem    Problem definition to be used for submission
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)reportProblemWithStop:(OBAReportProblemWithStopV2 *)problem
                                    completionBlock:(OBADataSourceCompletion)completion;
/**
 *  Makes an asynchronous request to report a problem with a trip
 *
 *  @param problem    Problem definition to be used for submission
 *  @param completion The block to be called once the request completes, this is always executed on the main thread.
 *
 *  @return The OBAModelServiceRequest object that allows request cancellation
 */
- (id<OBAModelServiceRequest>)reportProblemWithTrip:(OBAReportProblemWithTripV2 *)problem
                                    completionBlock:(OBADataSourceCompletion)completion;

@end

NS_ASSUME_NONNULL_END

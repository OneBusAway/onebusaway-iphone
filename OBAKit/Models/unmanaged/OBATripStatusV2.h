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

@import CoreLocation;
#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBATripInstanceRef.h>
#import <OBAKit/OBATripV2.h>
#import <OBAKit/OBAFrequencyV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATripStatusV2 : OBAHasReferencesV2

/**
 the trip id of the trip the vehicle is actively serving. All trip-specific values will be in reference to this active trip
 */
@property(nonatomic,copy) NSString * activeTripId;
/**
 The trip object referenced by the activeTripId.
 */
@property(nonatomic,weak,readonly) OBATripV2 * activeTrip;

/**
 time, in ms since the unix epoch, of midnight for start of the service date for the trip.
 */
@property(nonatomic,assign) long long serviceDate;

@property(nonatomic,strong) OBAFrequencyV2 * frequency;

/**
 the ID of the closest stop to the current location of the transit vehicle, whether from schedule or real-time predicted location data.
 */
@property(nonatomic,copy) NSString *closestStopID;

/**
 Current position of the transit vehicle. This element is optional, and will only be present if the trip is actively running. If real-time arrival data is available, the position will take that into account, otherwise the position reflects the scheduled position of the vehicle.
 */
@property(nonatomic,copy) CLLocation * position;

/**
 true if we have real-time arrival info available for this trip
 */
@property(nonatomic,assign) BOOL predicted;

/**
  if real-time arrival info is available, this lists the deviation from the schedule in seconds, where positive number indicates the trip is running late and negative indicates the trips is running early. If not real-time arrival info is available, this will be zero.
 */
@property(nonatomic,assign) NSInteger scheduleDeviation;

@property(nonatomic,copy,readonly) NSString *formattedScheduleDeviation;

/**
  if real-time arrival info is available, this lists the id of the transit vehicle currently running the trip.
 */
@property(nonatomic,copy) NSString * vehicleId;

/**
 the last known real-time update from the transit vehicle. Will be zero if we havent heard anything from the vehicle.
 */
@property(nonatomic,assign) long long lastUpdateTime;
/**
  Last known location of the transit vehicle. This differs from the existing position field, in that the position field is potential.
 */
@property(nonatomic,copy) CLLocation * lastKnownLocation;

@property(nonatomic,weak,readonly) OBATripInstanceRef * tripInstance;

@end

NS_ASSUME_NONNULL_END

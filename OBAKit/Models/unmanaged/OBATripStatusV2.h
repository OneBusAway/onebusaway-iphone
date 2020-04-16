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
@import MapKit;
#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBATripInstanceRef.h>
#import <OBAKit/OBATripV2.h>
#import <OBAKit/OBAFrequencyV2.h>

typedef NS_ENUM(NSUInteger, OBATripStatusModifier) {
    /// Something unstandardized is happening with this trip, depending on agency implementation. For
    /// example, this could be a detour or deadhead when operating on the MTA branch of OBA.
    OBATripStatusModifierOther      = 0,

    /// This trip is happening as described (AKA default).
    OBATripStatusModifierDefault    = 1,

    /// This trip is scheduled.
    OBATripStatusModifierScheduled  = 2,

    /// This trip has been canceled.
    OBATripStatusModifierCanceled   = 3
};

NS_ASSUME_NONNULL_BEGIN

@interface OBATripStatusV2 : OBAHasReferencesV2<MKAnnotation>

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
@property(nonatomic,copy,nullable) CLLocation * position;

/**
 true if we have real-time arrival info available for this trip
 */
@property(nonatomic,assign) BOOL predicted;

/**
  if real-time arrival info is available, this lists the deviation from the schedule in seconds, where positive number indicates the trip is running late and negative indicates the trips is running early. If not real-time arrival info is available, this will be zero.
 */
@property(nonatomic,assign) NSInteger scheduleDeviation;

@property(nonatomic,copy,readonly) NSString *formattedScheduleDeviation;

@property(nonatomic,copy) NSString *status;

/**
 status modifiers for the trip.
 */
@property(nonatomic,readonly) OBATripStatusModifier statusModifier;

/**
 if this trip's status modifier is marked as canceled.
 */
@property(nonatomic,readonly) BOOL isCanceled;

/**
  if real-time arrival info is available, this lists the id of the transit vehicle currently running the trip.
 */
@property(nonatomic,copy) NSString * vehicleId;

/**
 the last known real-time update from the transit vehicle. Will be zero if we havent heard anything from the vehicle.
 */
@property(nonatomic,assign) long long lastUpdateTime;

/**
 the last known real-time update from the transit vehicle. Will be nil if we havent heard anything from the vehicle.
 */
@property(nonatomic,copy,readonly) NSDate *lastUpdateDate;

/**
  Last known location of the transit vehicle. This differs from the existing position field, in that the position field is potential.
 */
@property(nonatomic,copy) CLLocation * lastKnownLocation;

/**
 The orientation of the transit vehicle, as an angle in degrees. Here, 0º is east, 90º is north, 180º is west, and 270º is south. This is an optional value that may be extrapolated from other data.
 */
@property(nonatomic,assign) CGFloat orientation;

@property(nonatomic,assign,readonly) CGFloat orientationInRadians;

/**
  the last known orientation value received in real-time from the transit vehicle.
 */
@property(nonatomic,assign) CGFloat lastKnownOrientation;

@property(nonatomic,weak,readonly) OBATripInstanceRef * tripInstance;

@end

NS_ASSUME_NONNULL_END

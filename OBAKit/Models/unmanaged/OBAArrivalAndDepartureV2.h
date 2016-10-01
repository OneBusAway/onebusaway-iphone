/*
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

#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBARouteV2.h>
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBATripV2.h>
#import <OBAKit/OBAFrequencyV2.h>
#import <OBAKit/OBATripStatusV2.h>
#import <OBAKit/OBATripInstanceRef.h>
#import <OBAKit/OBAArrivalAndDepartureInstanceRef.h>
#import <OBAKit/OBADepartureStatus.h>
#import <OBAKit/OBAHasServiceAlerts.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalAndDepartureV2 : OBAHasReferencesV2<OBAHasServiceAlerts>

@property(nonatomic,copy) NSString *routeId;
@property(nonatomic,weak,readonly) OBARouteV2 * route;
@property(nonatomic,copy) NSString *routeShortName;

@property(nonatomic,copy) NSString * tripId;
@property(nonatomic,weak,readonly) OBATripV2 * trip;
@property(nonatomic,copy,nullable) NSString * tripHeadsign;
@property(nonatomic,assign) long long serviceDate;

@property(nonatomic,weak,readonly) OBAArrivalAndDepartureInstanceRef * instance;
@property(nonatomic,weak,readonly) OBATripInstanceRef * tripInstance;

@property(nonatomic,copy) NSString * stopId;
@property(nonatomic,weak,readonly) OBAStopV2 * stop;
@property(nonatomic,assign) NSInteger stopSequence;

@property(nonatomic,strong) OBATripStatusV2 * tripStatus;

@property(nonatomic,strong) OBAFrequencyV2 * frequency;

@property(nonatomic,assign) BOOL predicted;

@property(nonatomic,assign) long long scheduledArrivalTime;
@property(nonatomic,assign) long long predictedArrivalTime;
@property(nonatomic,assign,readonly) long long bestArrivalTime;

@property(nonatomic,assign) long long scheduledDepartureTime;
@property(nonatomic,assign) long long predictedDepartureTime;
@property(nonatomic,assign,readonly) long long bestDepartureTime;
@property(nonatomic,copy,readonly) NSDate *bestDeparture;

@property(nonatomic,assign) double distanceFromStop;
@property(nonatomic,assign) NSInteger numberOfStopsAway;

- (BOOL)hasRealTimeData;

/**
 This string is composed of this object's routeId, tripHeadsign, and bestAvailableName.
 It is designed to offer a unique key for determining bookmark existence during the process of creating one.
 */
- (NSString*)bookmarkKey;

/**
 Walks through a series of possible options for giving this arrival and departure a user-sensible name.

 @return A string (hopefully) suitable for presenting to the user.
 */
- (NSString*)bestAvailableName;

- (OBADepartureStatus)departureStatus;

- (NSString*)statusText;

/**
 How far off is this vehicle from its predicted, scheduled time?

 @return `NaN` when real time data is unavailable. Negative is early, positive is delayed.
 */
- (double)predictedDepatureTimeDeviationFromScheduleInMinutes;

/**
 How far away are we right now from the best departure time available to us? Uses real time data when available, and scheduled data otherwise.

 @return The number of minutes until departure, suitable to display to a user.
 */
- (NSInteger)minutesUntilBestDeparture;

- (NSComparisonResult)compareRouteName:(OBAArrivalAndDepartureV2*)dep;

/**
 Determines whether the receiver and the arrivalAndDeparture parameter
 have equivalent trip IDs, headsigns, and stop IDs. In other words,
 do they represent the same trip, regardless of when that trip occurs?

 @param arrivalAndDeparture The arrival and departure object to compare to the receiver.

 @return true if they represent the same route, and false otherwise.
 */
- (BOOL)routesAreEquivalent:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

@end

NS_ASSUME_NONNULL_END

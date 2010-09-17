/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBARoute.h"
#import "OBAStop.h"

@interface OBAArrivalAndDeparture : NSObject {
	
	OBARoute * _route;
	NSString * _routeShortName;

	NSString * _tripId;
	NSString * _tripHeadsign;

	long long _scheduledArrivalTime;
	long long _predictedArrivalTime;
	long long _scheduledDepartureTime;
	long long _predictedDepartureTime;
}

@property (nonatomic,retain) OBARoute * route;
@property (nonatomic,retain) NSString * routeShortName;
@property (nonatomic,retain) NSString * tripId;
@property (nonatomic,retain) NSString * tripHeadsign;

@property (nonatomic) long long scheduledArrivalTime;
@property (nonatomic) long long predictedArrivalTime;
@property (nonatomic,readonly) long long bestArrivalTime;

@property (nonatomic) long long scheduledDepartureTime;
@property (nonatomic) long long predictedDepartureTime;
@property (nonatomic,readonly) long long bestDepartureTime;

@end

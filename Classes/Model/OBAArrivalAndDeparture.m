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

#import "OBAArrivalAndDeparture.h"


@implementation OBAArrivalAndDeparture

@synthesize route = _route;
@synthesize routeShortName = _routeShortName;
@synthesize tripId = _tripId;
@synthesize tripHeadsign = _tripHeadsign;

@synthesize scheduledArrivalTime = _scheduledArrivalTime;
@synthesize predictedArrivalTime = _predictedArrivalTime;

@synthesize scheduledDepartureTime = _scheduledDepartureTime;
@synthesize predictedDepartureTime = _predictedDepartureTime;

- (void) dealloc {
	[_route release];
	[_routeShortName release];
	[_tripId release];
	[_tripHeadsign release];
	
	[super dealloc];
}
- (long long) bestArrivalTime {
	return _predictedArrivalTime == 0 ? _scheduledArrivalTime : _predictedArrivalTime;
}

- (long long) bestDepartureTime {
	return _predictedDepartureTime == 0 ? _scheduledDepartureTime : _predictedDepartureTime;
}

@end

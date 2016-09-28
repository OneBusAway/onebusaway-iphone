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
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBAHasServiceAlerts.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalsAndDeparturesForStopV2 : OBAHasReferencesV2<OBAHasServiceAlerts>
@property(nonatomic,strong) NSString *stopId;
@property(nonatomic,weak,readonly) OBAStopV2 *stop;
@property(nonatomic,strong,readonly) NSArray<OBAArrivalAndDepartureV2*> *arrivalsAndDepartures;

- (void)addArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

/**
 Tells the caller whether any scheduled arrivals or departures are represented in this object.

 @return true if some scheduled data exists, false if it is all realtime data.
 */
- (BOOL)lacksRealTimeData;

@end

NS_ASSUME_NONNULL_END

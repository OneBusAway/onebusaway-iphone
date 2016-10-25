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

@import Foundation;

@class OBAAgencyV2;
@class OBARouteV2;
@class OBAStopV2;
@class OBATripV2;
@class OBASituationV2;

NS_ASSUME_NONNULL_BEGIN

@interface OBAReferencesV2 : NSObject
- (void)addAgency:(OBAAgencyV2*)agency;
- (nullable OBAAgencyV2*)getAgencyForId:(NSString*)agencyId;
- (NSDictionary*) getAllAgencies;

- (void)addRoute:(OBARouteV2*)route;
- (nullable OBARouteV2*)getRouteForId:(NSString*)routeId;

- (void)addStop:(OBAStopV2*)stop;
- (nullable OBAStopV2*)getStopForId:(NSString*)stopId;

- (void)addTrip:(OBATripV2*)trip;
- (nullable OBATripV2*)getTripForId:(NSString*)tripId;

- (void)addSituation:(OBASituationV2*)situation;
- (nullable OBASituationV2*)getSituationForId:(NSString*)situationId;

- (void)clear;
@end

NS_ASSUME_NONNULL_END

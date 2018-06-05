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

#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBAEntryWithReferencesV2.h>
#import <OBAKit/OBAListWithRangeAndReferencesV2.h>
#import <OBAKit/OBAArrivalsAndDeparturesForStopV2.h>
#import <OBAKit/OBAStopsForRouteV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAModelFactory : NSObject
@property(nonatomic,strong,readonly) OBAReferencesV2 *references;

- (instancetype)initWithReferences:(OBAReferencesV2*)references;

/**
 Convenience initializer with `references` plumbed in.
 */
+ (instancetype)modelFactory;

- (OBAListWithRangeAndReferencesV2*) getRoutesV2FromJSON:(NSDictionary*)jsonArray error:(NSError**)error;

- (OBAEntryWithReferencesV2*) getStopFromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error;
- (OBAListWithRangeAndReferencesV2*) getStopsV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error;

- (OBAStopsForRouteV2*) getStopsForRouteV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error;
- (OBAListWithRangeAndReferencesV2*) getAgenciesWithCoverageV2FromJson:(id)jsonDictionary error:(NSError**)error;
- (OBAListWithRangeAndReferencesV2*) getRegionsV2FromJson:(id)jsonDictionary error:(NSError**)error;
- (OBAArrivalsAndDeparturesForStopV2*) getArrivalsAndDeparturesForStopV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error;
- (OBAEntryWithReferencesV2*)getArrivalAndDepartureForStopV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error;
- (OBAEntryWithReferencesV2*) getTripDetailsV2FromJSON:(NSDictionary*)json error:(NSError**)error;

- (OBAEntryWithReferencesV2*) getVehicleStatusV2FromJSON:(NSDictionary*)json error:(NSError**)error;

- (NSString*) getShapeV2FromJSON:(NSDictionary*)json error:(NSError*)error;

@end

NS_ASSUME_NONNULL_END

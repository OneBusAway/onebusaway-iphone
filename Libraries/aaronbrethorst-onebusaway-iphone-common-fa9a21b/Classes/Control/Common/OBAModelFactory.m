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

#import "OBAModelFactory.h"
#import "OBALogger.h"

#import "OBAReferencesV2.h"
#import "OBAAgencyV2.h"
#import "OBARouteV2.h"
#import "OBAStopV2.h"
#import "OBATripV2.h"
#import "OBATripDetailsV2.h"
#import "OBATripScheduleV2.h"
#import "OBATripStopTimeV2.h"
#import "OBATripStatusV2.h"
#import "OBAItinerariesV2.h"

#import "OBAVehicleStatusV2.h"

#import "OBASituationV2.h"
#import "OBASituationConsequenceV2.h"

#import "OBAAgencyWithCoverageV2.h"
#import "OBAPlacemark.h"

#import "OBACurrentVehicleEstimateV2.h"

#import "OBAJsonDigester.h"
#import "OBASetCoordinatePropertyJsonDigesterRule.h"
#import "OBASetLocationPropertyJsonDigesterRule.h"
#import "OBASetDatePropertyJsonDigesterRule.h"

#import "OBARegionV2.h"
#import "OBARegionBoundsV2.h"

static NSString * const kReferences = @"references";

@interface OBAModelFactory (Private)

- (NSDictionary*) getDigesterParameters;

@end


@interface OBAJsonDigester (CustomDigesterRules)

- (void) addReferencesRulesWithPrefix:(NSString*)prefix;

- (void) addAgencyV2RulesWithPrefix:(NSString*)prefix;
- (void) addRouteV2RulesWithPrefix:(NSString*)prefix;
- (void) addStopV2RulesWithPrefix:(NSString*)prefix;
- (void) addTripV2RulesWithPrefix:(NSString*)prefix;
- (void) addSituationV2RulesWithPrefix:(NSString*)prefix;
- (void) addTripDetailsV2RulesWithPrefix:(NSString*)prefix;

- (void) addItinerariesV2RulesWithPrefix:(NSString*)prefix;
- (void) addItineraryV2RulesWithPrefix:(NSString*)prefix;
- (void) addLegV2RulesWithPrefix:(NSString*)prefix;
- (void) addTransitLegV2RulesWithPrefix:(NSString*)prefix;
- (void) addStreetLegV2RulesWithPrefix:(NSString*)prefix;

- (void) addAgencyWithCoverageV2RulesWithPrefix:(NSString*)prefix;

- (void) addArrivalAndDepartureV2RulesWithPrefix:(NSString*)prefix;
- (void) addTripStatusV2RulesWithPrefix:(NSString*)prefix;
- (void) addFrequencyV2RulesWithPrefix:(NSString*)prefix;

- (void) addCurrentVehicleEstimateV2RulesWithPrefix:(NSString*)prefix;

- (void) addVehicleStatusV2RulesWithPrefix:(NSString*)prefix;

- (void) addAgencyToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) addRouteToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) addStopToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) addTripToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) addSituationToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;

- (void) setReferencesForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;

- (void) addSetCoordinatePropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix method:(OBASetCoordinatePropertyMethod)method;
- (void) addSetLocationPropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix;
- (void) addSetDatePropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix;

- (void) addRegionV2RulesWithPrefix:(NSString*)prefix;
- (void) addRegionBoundsV2RulesWithPrefix:(NSString*)prefix;
@end


@implementation OBAModelFactory

- (id) initWithReferences:(OBAReferencesV2*)references {
    
    self = [super init];
    
    if( self ) {
        _references = references;
        _entityIdMappings = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (OBAEntryWithReferencesV2*) getStopFromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
    
    OBAEntryWithReferencesV2 * entry = [[OBAEntryWithReferencesV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addStopV2RulesWithPrefix:@"/entry"];
    [digester addSetNext:@selector(setEntry:) forPrefix:@"/entry"];
    
    [digester parse:jsonDictionary withRoot:entry parameters:[self getDigesterParameters] error:error];
    
    return entry;
}

- (OBAListWithRangeAndReferencesV2*) getStopsV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
    
    OBAListWithRangeAndReferencesV2 * list = [[OBAListWithRangeAndReferencesV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addSetPropertyRule:@"outOfRange" forPrefix:@"/outOfRange"];
    [digester addSetPropertyRule:@"limitExceeded" forPrefix:@"/limitExceeded"];
    [digester addStopV2RulesWithPrefix:@"/list/[]"];
    [digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
    
    [digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
    
    return list;
}

- (OBAListWithRangeAndReferencesV2*) getRoutesV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
    
    OBAListWithRangeAndReferencesV2 * list = [[OBAListWithRangeAndReferencesV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addRouteV2RulesWithPrefix:@"/list/[]"];
    [digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
    
    [digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
    
    return list;
}

- (OBAStopsForRouteV2*) getStopsForRouteV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {

    OBAStopsForRouteV2 * result = [[OBAStopsForRouteV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addCallMethodRule:@selector(addStopId:) forPrefix:@"/entry/stopIds/[]"];
    [digester addCallMethodRule:@selector(addPolyline:) forPrefix:@"/entry/polylines/[]/points"];
    [digester parse:jsonDictionary withRoot:result parameters:[self getDigesterParameters] error:error];
    
    return result;
}

- (OBAListWithRangeAndReferencesV2*) getAgenciesWithCoverageV2FromJson:(id)jsonDictionary error:(NSError**)error {
    
    OBAListWithRangeAndReferencesV2 * list = [[OBAListWithRangeAndReferencesV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addAgencyWithCoverageV2RulesWithPrefix:@"/list/[]"];
    [digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
    
    [digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
    
    return list;
}

- (OBAListWithRangeAndReferencesV2*) getRegionsV2FromJson:(id)jsonDictionary error:(NSError**)error {
        OBAListWithRangeAndReferencesV2 * list = [[OBAListWithRangeAndReferencesV2 alloc] initWithReferences:_references];
    
        OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
        [digester addRegionV2RulesWithPrefix:@"/data/list/[]"];
        [digester addSetNext:@selector(addValue:) forPrefix:@"/data/list/[]"];
        [digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
    
        return list;
}

- (OBAArrivalsAndDeparturesForStopV2*) getArrivalsAndDeparturesForStopV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {

    OBAArrivalsAndDeparturesForStopV2 * ads = [[OBAArrivalsAndDeparturesForStopV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addSetPropertyRule:@"stopId" forPrefix:@"/entry/stopId"];
    [digester addArrivalAndDepartureV2RulesWithPrefix:@"/entry/arrivalsAndDepartures/[]"];
    [digester addSetNext:@selector(addArrivalAndDeparture:) forPrefix:@"/entry/arrivalsAndDepartures/[]"];    
    [digester addCallMethodRule:@selector(addSituationId:) forPrefix:@"/entry/situationIds/[]"];
    
    [digester parse:jsonDictionary withRoot:ads parameters:[self getDigesterParameters] error:error];
    
    return ads;
}

- (OBAEntryWithReferencesV2*) getArrivalAndDepartureForStopV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
    
    OBAEntryWithReferencesV2 * entry = [[OBAEntryWithReferencesV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addArrivalAndDepartureV2RulesWithPrefix:@"/entry"];
    [digester addSetNext:@selector(setEntry:) forPrefix:@"/entry"];
    
    [digester parse:jsonDictionary withRoot:entry parameters:[self getDigesterParameters] error:error];
    
    return entry;
}

- (NSArray*) getPlacemarksFromJSONObject:(id)jsonObject error:(NSError**)error {
    
    NSMutableArray * placemarks = [NSMutableArray array];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addObjectCreateRule:[OBAPlacemark class] forPrefix:@"/Placemark/[]"];
    [digester addSetPropertyRule:@"address" forPrefix:@"/Placemark/[]/address"];
    [digester addSetNext:@selector(addObject:) forPrefix:@"/Placemark/[]"];
    
    OBASetCoordinatePropertyJsonDigesterRule * rule = [[OBASetCoordinatePropertyJsonDigesterRule alloc] initWithPropertyName:@"coordinate" method:OBASetCoordinatePropertyMethodArray];
    
    [digester addRule:rule forPrefix:@"/Placemark/[]/Point/coordinates"];
    
    [digester parse:jsonObject withRoot:placemarks parameters:[self getDigesterParameters] error:error];
    
    return placemarks;
}

- (OBAPlacemarks*) getPlacemarksFromGooglePlacesJSONObject:(id)jsonObject error:(NSError**)error {

    OBAPlacemarks * placemarks = [[OBAPlacemarks alloc] init];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addObjectCreateRule:[OBAPlacemark class] forPrefix:@"/results/[]"];
    [digester addSetPropertyRule:@"name" forPrefix:@"/results/[]/name"];
    [digester addSetPropertyRule:@"address" forPrefix:@"/results/[]/vicinity"];
    [digester addSetPropertyRule:@"icon" forPrefix:@"/results/[]/icon"];
    
    OBASetCoordinatePropertyJsonDigesterRule * rule = [[OBASetCoordinatePropertyJsonDigesterRule alloc] initWithPropertyName:@"coordinate" method:OBASetCoordinatePropertyMethodLatLon];
    rule.lonJsonName = @"lng";
    [digester addRule:rule forPrefix:@"/results/[]/geometry/location"];
    
    [digester addSetNext:@selector(addPlacemark:) forPrefix:@"/results/[]"];
    
    [digester addCallMethodRule:@selector(addAttribution:) forPrefix:@"/html_attributions/[]"];
    
    [digester parse:jsonObject withRoot:placemarks parameters:[self getDigesterParameters] error:error];
    
    return placemarks;
}

- (OBAEntryWithReferencesV2*) getTripDetailsV2FromJSON:(NSDictionary*)json error:(NSError**)error {

    OBAEntryWithReferencesV2 * entry = [[OBAEntryWithReferencesV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addTripDetailsV2RulesWithPrefix:@"/entry"];
    [digester addSetNext:@selector(setEntry:) forPrefix:@"/entry"];
    
    [digester parse:json withRoot:entry parameters:[self getDigesterParameters] error:error];
    
    return entry;
}

- (OBAEntryWithReferencesV2*) getVehicleStatusV2FromJSON:(NSDictionary*)json error:(NSError**)error {

    OBAEntryWithReferencesV2 * entry = [[OBAEntryWithReferencesV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addVehicleStatusV2RulesWithPrefix:@"/entry"];
    [digester addSetNext:@selector(setEntry:) forPrefix:@"/entry"];
    
    [digester parse:json withRoot:entry parameters:[self getDigesterParameters] error:error];
    
    return entry;
}

- (OBAListWithRangeAndReferencesV2*) getCurrentVehicleEstimatesV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
    
    OBAListWithRangeAndReferencesV2 * list = [[OBAListWithRangeAndReferencesV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addSetPropertyRule:@"limitExceeded" forPrefix:@"/limitExceeded"];
    [digester addCurrentVehicleEstimateV2RulesWithPrefix:@"/list/[]"];
    [digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
    
    [digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
    
    return list;
}

- (OBAEntryWithReferencesV2*) getItinerariesV2FromJSON:(NSDictionary*)json error:(NSError**)error {
    
    OBAEntryWithReferencesV2 * entry = [[OBAEntryWithReferencesV2 alloc] initWithReferences:_references];
    
    OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
    [digester addReferencesRulesWithPrefix:@"/references"];
    [digester addItinerariesV2RulesWithPrefix:@"/entry"];
    [digester addSetNext:@selector(setEntry:) forPrefix:@"/entry"];
    
    [digester parse:json withRoot:entry parameters:[self getDigesterParameters] error:error];
    
    return entry;

}

- (NSString*) getAlarmIdFromJSON:(NSString*)alarmId error:(NSError*)error {
    return alarmId;
}

- (NSString*) getShapeV2FromJSON:(NSDictionary*)json error:(NSError*)error {
    NSDictionary * entry = json[@"entry"];
    return entry[@"points"];
}

@end

@implementation OBAModelFactory (Private)

- (NSDictionary*) getDigesterParameters {
    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    params[kReferences] = _references;
    return params;
}

@end

    
@implementation OBAJsonDigester (CustomDigesterRules)

- (void) addReferencesRulesWithPrefix:(NSString*)prefix {
    
    NSString * agencyPrefix = [self extendPrefix:prefix withValue:@"agencies/[]"];
    [self addAgencyV2RulesWithPrefix:agencyPrefix];

    NSString * routePrefix = [self extendPrefix:prefix withValue:@"routes/[]"];
    [self addRouteV2RulesWithPrefix:routePrefix];
    
    NSString * stopPrefix = [self extendPrefix:prefix withValue:@"stops/[]"];
    [self addStopV2RulesWithPrefix:stopPrefix];
    
    NSString * tripPrefix = [self extendPrefix:prefix withValue:@"trips/[]"];
    [self addTripV2RulesWithPrefix:tripPrefix];
    
    NSString * situationPrefix = [self extendPrefix:prefix withValue:@"situations/[]"];
    [self addSituationV2RulesWithPrefix:situationPrefix];

}

- (void) addAgencyV2RulesWithPrefix:(NSString*)prefix {    
    [self addObjectCreateRule:[OBAAgencyV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"agencyId" forPrefix:[self extendPrefix:prefix withValue:@"id"]];
    [self addSetPropertyRule:@"name" forPrefix:[self extendPrefix:prefix withValue:@"name"]];
    [self addSetPropertyRule:@"url" forPrefix:[self extendPrefix:prefix withValue:@"url"]];    
    [self addTarget:self selector:@selector(addAgencyToReferences:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
}

- (void) addRouteV2RulesWithPrefix:(NSString*)prefix {    
    [self addObjectCreateRule:[OBARouteV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"routeId" forPrefix:[self extendPrefix:prefix withValue:@"id"]];
    [self addSetOptionalPropertyRule:@"shortName" forPrefix:[self extendPrefix:prefix withValue:@"shortName"]];
    [self addSetOptionalPropertyRule:@"longName" forPrefix:[self extendPrefix:prefix withValue:@"longName"]];
    [self addSetPropertyRule:@"routeType" forPrefix:[self extendPrefix:prefix withValue:@"type"]];
    [self addSetPropertyRule:@"agencyId" forPrefix:[self extendPrefix:prefix withValue:@"agencyId"]];
    [self addTarget:self selector:@selector(addRouteToReferences:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
}

- (void) addStopV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBAStopV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"stopId" forPrefix:[self extendPrefix:prefix withValue:@"id"]];    
    [self addSetPropertyRule:@"name" forPrefix:[self extendPrefix:prefix withValue:@"name"]];
    [self addSetOptionalPropertyRule:@"code" forPrefix:[self extendPrefix:prefix withValue:@"code"]]; // Optional
    [self addSetOptionalPropertyRule:@"direction" forPrefix:[self extendPrefix:prefix withValue:@"direction"]]; // Optional
    [self addSetPropertyRule:@"latitude" forPrefix:[self extendPrefix:prefix withValue:@"lat"]];
    [self addSetPropertyRule:@"longitude" forPrefix:[self extendPrefix:prefix withValue:@"lon"]];
    [self addSetPropertyRule:@"routeIds" forPrefix:[self extendPrefix:prefix withValue:@"routeIds"]];
    [self addTarget:self selector:@selector(addStopToReferences:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
}

- (void) addTripV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBATripV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"tripId" forPrefix:[self extendPrefix:prefix withValue:@"id"]];    
    [self addSetPropertyRule:@"routeId" forPrefix:[self extendPrefix:prefix withValue:@"routeId"]];
    [self addSetOptionalPropertyRule:@"routeShortName" forPrefix:[self extendPrefix:prefix withValue:@"routeShortName"]];
    [self addSetOptionalPropertyRule:@"tripShortName" forPrefix:[self extendPrefix:prefix withValue:@"tripShortName"]];
    [self addSetOptionalPropertyRule:@"tripHeadsign" forPrefix:[self extendPrefix:prefix withValue:@"tripHeadsign"]];
    [self addSetPropertyRule:@"serviceId" forPrefix:[self extendPrefix:prefix withValue:@"serviceId"]];
    [self addSetOptionalPropertyRule:@"shapeId" forPrefix:[self extendPrefix:prefix withValue:@"shapeId"]];
    [self addSetOptionalPropertyRule:@"directionId" forPrefix:[self extendPrefix:prefix withValue:@"directionId"]];
    [self addSetOptionalPropertyRule:@"blockId" forPrefix:[self extendPrefix:prefix withValue:@"blockId"]];
    [self addTarget:self selector:@selector(addTripToReferences:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];    
}

- (void) addSituationV2RulesWithPrefix:(NSString*)prefix {
    
    
    [self addObjectCreateRule:[OBASituationV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"situationId" forPrefix:[self extendPrefix:prefix withValue:@"id"]];    
    [self addSetPropertyRule:@"creationTime" forPrefix:[self extendPrefix:prefix withValue:@"creationTime"]];
    [self addSetOptionalPropertyRule:@"summary" forPrefix:[self extendPrefix:prefix withValue:@"summary/value"]];
    [self addSetOptionalPropertyRule:@"description" forPrefix:[self extendPrefix:prefix withValue:@"description/value"]];
    [self addSetOptionalPropertyRule:@"advice" forPrefix:[self extendPrefix:prefix withValue:@"advice/value"]];
    
    [self addSetOptionalPropertyRule:@"severity" forPrefix:[self extendPrefix:prefix withValue:@"severity"]];
    [self addSetOptionalPropertyRule:@"sensitivity" forPrefix:[self extendPrefix:prefix withValue:@"sensitivity"]];
    
    NSString * consequencesPrefix = [self extendPrefix:prefix withValue:@"consequences"];
    [self addObjectCreateRule:[NSMutableArray class] forPrefix:consequencesPrefix];
    [self addSetNext:@selector(setConsequences:) forPrefix:consequencesPrefix];
    
    NSString * consequencePrefix = [self extendPrefix:consequencesPrefix withValue:@"[]"];
    [self addObjectCreateRule:[OBASituationConsequenceV2 class] forPrefix:consequencePrefix];
    [self addSetPropertyRule:@"condition" forPrefix:[self extendPrefix:consequencePrefix withValue:@"condition"]];
    [self addSetPropertyRule:@"diversionPath" forPrefix:[self extendPrefix:consequencePrefix withValue:@"conditionDetails/diversionPath/points"]];
    [self addSetNext:@selector(addObject:) forPrefix:consequencePrefix];
    
    [self addTarget:self selector:@selector(addSituationToReferences:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
}

- (void) addTripDetailsV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBATripDetailsV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"tripId" forPrefix:[self extendPrefix:prefix withValue:@"tripId"]];
    [self addSetPropertyRule:@"serviceDate" forPrefix:[self extendPrefix:prefix withValue:@"serviceDate"]];
    [self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
    [self addCallMethodRule:@selector(addSituationId:) forPrefix:[self extendPrefix:prefix withValue:@"situationIds/[]"]];
    
    NSString * schedulePrefix = [self extendPrefix:prefix withValue:@"schedule"];
    [self addObjectCreateRule:[OBATripScheduleV2 class] forPrefix:schedulePrefix];
    [self addSetOptionalPropertyRule:@"previousTripId" forPrefix:[self extendPrefix:schedulePrefix withValue:@"previousTripId"]];
    [self addSetOptionalPropertyRule:@"nextTripId" forPrefix:[self extendPrefix:schedulePrefix withValue:@"nextTripId"]];
    [self addSetNext:@selector(setSchedule:) forPrefix:schedulePrefix];
    [self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:schedulePrefix];
    
    NSString * scheduleFrequencyPrefix = [self extendPrefix:schedulePrefix withValue:@"frequency"];
    [self addFrequencyV2RulesWithPrefix:scheduleFrequencyPrefix];
    [self addSetNext:@selector(setFrequency:) forPrefix:scheduleFrequencyPrefix];
    
    NSString * stopTimesArrayPrefix = [self extendPrefix:prefix withValue:@"schedule/stopTimes"];
    [self addObjectCreateRule:[NSMutableArray class] forPrefix:stopTimesArrayPrefix];
    [self addSetNext:@selector(setStopTimes:) forPrefix:stopTimesArrayPrefix];
    
    NSString * stopTimesPrefix = [self extendPrefix:stopTimesArrayPrefix withValue:@"[]"];
    [self addObjectCreateRule:[OBATripStopTimeV2 class] forPrefix:stopTimesPrefix];
    [self addSetPropertyRule:@"arrivalTime" forPrefix:[self extendPrefix:stopTimesPrefix withValue:@"arrivalTime"]];
    [self addSetPropertyRule:@"departureTime" forPrefix:[self extendPrefix:stopTimesPrefix withValue:@"departureTime"]];
    [self addSetPropertyRule:@"stopId" forPrefix:[self extendPrefix:stopTimesPrefix withValue:@"stopId"]];
    [self addSetNext:@selector(addObject:) forPrefix:stopTimesPrefix];
    [self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:stopTimesPrefix];
    
    NSString * tripStatusPrefix = [self extendPrefix:prefix withValue:@"status"];
    [self addTripStatusV2RulesWithPrefix:tripStatusPrefix];
    [self addSetNext:@selector(setStatus:) forPrefix:tripStatusPrefix];
}

- (void) addItinerariesV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBAItinerariesV2 class] forPrefix:prefix];
    [self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];

    NSString * itineraryPrefix = [self extendPrefix:prefix withValue:@"itineraries/[]"];
    [self addItineraryV2RulesWithPrefix:itineraryPrefix];
    [self addSetNext:@selector(addItinerary:) forPrefix:itineraryPrefix];
}

- (void) addItineraryV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBAItineraryV2 class] forPrefix:prefix];
    [self addSetDatePropertyRule:@"startTime" withPrefix:[self extendPrefix:prefix withValue:@"startTime"]];
    [self addSetDatePropertyRule:@"endTime" withPrefix:[self extendPrefix:prefix withValue:@"endTime"]];
    [self addSetPropertyRule:@"probability" forPrefix:[self extendPrefix:prefix withValue:@"probability"]];
    [self addSetPropertyRule:@"selected" forPrefix:[self extendPrefix:prefix withValue:@"selected"]];    
    [self addSetPropertyRule:@"rawData" forPrefix:prefix];
    
    NSString * legPrefix = [self extendPrefix:prefix withValue:@"legs/[]"];
    [self addLegV2RulesWithPrefix:legPrefix];
    [self addSetNext:@selector(addLeg:) forPrefix:legPrefix];   
}

- (void) addLegV2RulesWithPrefix:(NSString*)prefix {

    [self addObjectCreateRule:[OBALegV2 class] forPrefix:prefix];
    [self addSetDatePropertyRule:@"startTime" withPrefix:[self extendPrefix:prefix withValue:@"startTime"]];
    [self addSetDatePropertyRule:@"endTime" withPrefix:[self extendPrefix:prefix withValue:@"endTime"]];
    [self addSetPropertyRule:@"mode" forPrefix:[self extendPrefix:prefix withValue:@"mode"]];
    [self addSetPropertyRule:@"distance" forPrefix:[self extendPrefix:prefix withValue:@"distance"]];

    NSString * transitLegPrefix = [self extendPrefix:prefix withValue:@"transitLeg"];
    [self addTransitLegV2RulesWithPrefix:transitLegPrefix];
    [self addSetNext:@selector(setTransitLeg:) forPrefix:transitLegPrefix];
    
    NSString * streetLegPrefix = [self extendPrefix:prefix withValue:@"streetLegs/[]"];
    [self addStreetLegV2RulesWithPrefix:streetLegPrefix];
    [self addSetNext:@selector(addStreetLeg:) forPrefix:streetLegPrefix];
}

- (void) addTransitLegV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBATransitLegV2 class] forPrefix:prefix];
    [self addSetOptionalPropertyRule:@"tripId" forPrefix:[self extendPrefix:prefix withValue:@"tripId"]];
    [self addSetPropertyRule:@"serviceDate" forPrefix:[self extendPrefix:prefix withValue:@"serviceDate"]];
    [self addSetOptionalPropertyRule:@"vehicleId" forPrefix:[self extendPrefix:prefix withValue:@"vehicleId"]];
    
    NSString * frequencyPrefix = [self extendPrefix:prefix withValue:@"frequency"];
    [self addFrequencyV2RulesWithPrefix:frequencyPrefix];
    [self addSetNext:@selector(setFrequency:) forPrefix:frequencyPrefix];

    [self addSetOptionalPropertyRule:@"fromStopId" forPrefix:[self extendPrefix:prefix withValue:@"fromStopId"]];
    [self addSetPropertyRule:@"fromStopSequence" forPrefix:[self extendPrefix:prefix withValue:@"fromStopSequence"]];
    [self addSetOptionalPropertyRule:@"toStopId" forPrefix:[self extendPrefix:prefix withValue:@"toStopId"]];
    [self addSetPropertyRule:@"toStopSequence" forPrefix:[self extendPrefix:prefix withValue:@"toStopSequence"]];
    [self addSetOptionalPropertyRule:@"tripHeadsign" forPrefix:[self extendPrefix:prefix withValue:@"tripHeadsign"]];
    [self addSetOptionalPropertyRule:@"path" forPrefix:[self extendPrefix:prefix withValue:@"path"]];
    [self addSetPropertyRule:@"scheduledDepartureTime" forPrefix:[self extendPrefix:prefix withValue:@"scheduledDepartureTime"]];
    [self addSetPropertyRule:@"predictedDepartureTime" forPrefix:[self extendPrefix:prefix withValue:@"predictedDepartureTime"]];
    [self addSetPropertyRule:@"scheduledArrivalTime" forPrefix:[self extendPrefix:prefix withValue:@"scheduledArrivalTime"]];
    [self addSetPropertyRule:@"predictedArrivalTime" forPrefix:[self extendPrefix:prefix withValue:@"predictedArrivalTime"]];
    [self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
}

- (void) addStreetLegV2RulesWithPrefix:(NSString*)prefix { 
    [self addObjectCreateRule:[OBAStreetLegV2 class] forPrefix:prefix];
    [self addSetOptionalPropertyRule:@"streetName" forPrefix:[self extendPrefix:prefix withValue:@"streetName"]];
    [self addSetOptionalPropertyRule:@"path" forPrefix:[self extendPrefix:prefix withValue:@"path"]];
    [self addSetPropertyRule:@"distance" forPrefix:[self extendPrefix:prefix withValue:@"distance"]];
}



- (void) addAgencyWithCoverageV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBAAgencyWithCoverageV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"agencyId" forPrefix:[self extendPrefix:prefix withValue:@"agencyId"]];    
    [self addSetCoordinatePropertyRule:@"coordinate" withPrefix:prefix method:OBASetCoordinatePropertyMethodLatLon];
    [self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
}

- (void) addArrivalAndDepartureV2RulesWithPrefix:(NSString*)prefix {
    
    [self addObjectCreateRule:[OBAArrivalAndDepartureV2 class] forPrefix:prefix];
    
    [self addSetPropertyRule:@"routeId" forPrefix:[self extendPrefix:prefix withValue:@"routeId"]];
    [self addSetOptionalPropertyRule:@"routeShortName" forPrefix:[self extendPrefix:prefix withValue:@"routeShortName"]];
    
    [self addSetPropertyRule:@"tripId" forPrefix:[self extendPrefix:prefix withValue:@"tripId"]];
    [self addSetOptionalPropertyRule:@"tripHeadsign" forPrefix:[self extendPrefix:prefix withValue:@"tripHeadsign"]];
    [self addSetPropertyRule:@"serviceDate" forPrefix:[self extendPrefix:prefix withValue:@"serviceDate"]];
    
    [self addSetPropertyRule:@"stopId" forPrefix:[self extendPrefix:prefix withValue:@"stopId"]];
    [self addSetPropertyRule:@"stopSequence" forPrefix:[self extendPrefix:prefix withValue:@"stopSequence"]];
    
    NSString * tripStatusPrefix = [self extendPrefix:prefix withValue:@"tripStatus"];
    [self addTripStatusV2RulesWithPrefix:tripStatusPrefix];
    [self addSetNext:@selector(setTripStatus:) forPrefix:tripStatusPrefix];

    [self addSetPropertyRule:@"predicted" forPrefix:[self extendPrefix:prefix withValue:@"predicted"]];
    
    [self addSetPropertyRule:@"scheduledArrivalTime" forPrefix:[self extendPrefix:prefix withValue:@"scheduledArrivalTime"]];
    [self addSetPropertyRule:@"predictedArrivalTime" forPrefix:[self extendPrefix:prefix withValue:@"predictedArrivalTime"]];
    [self addSetPropertyRule:@"scheduledDepartureTime" forPrefix:[self extendPrefix:prefix withValue:@"scheduledDepartureTime"]];
    [self addSetPropertyRule:@"predictedDepartureTime" forPrefix:[self extendPrefix:prefix withValue:@"predictedDepartureTime"]];
    
    [self addSetPropertyRule:@"distanceFromStop" forPrefix:[self extendPrefix:prefix withValue:@"distanceFromStop"]];
    
    NSString * frequencyPrefix = [self extendPrefix:prefix withValue:@"frequency"];
    [self addFrequencyV2RulesWithPrefix:frequencyPrefix];
    [self addSetNext:@selector(setFrequency:) forPrefix:frequencyPrefix];
    
    [self addCallMethodRule:@selector(addSituationId:) forPrefix:[self extendPrefix:prefix withValue:@"situationIds/[]"]];
    
    [self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
}

- (void) addRegionV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBARegionV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"siriBaseUrl" forPrefix:[self extendPrefix:prefix withValue:@"siriBaseUrl"]];
    [self addSetPropertyRule:@"obaVersionInfo" forPrefix:[self extendPrefix:prefix withValue:@"obaVersionInfo"]];
    [self addSetPropertyRule:@"supportsSiriRealtimeApis" forPrefix:[self extendPrefix:prefix withValue:@"supportsSiriRealtimeApis"]];
    [self addSetPropertyRule:@"language" forPrefix:[self extendPrefix:prefix withValue:@"language"]];
    [self addSetPropertyRule:@"supportsObaRealtimeApis" forPrefix:[self extendPrefix:prefix withValue:@"supportsObaRealtimeApis"]];

    NSString * regionBoundsPrefix = [self extendPrefix:prefix withValue:@"bounds/[]"];
    [self addRegionBoundsV2RulesWithPrefix:regionBoundsPrefix];
    [self addSetNext:@selector(addBound:) forPrefix:regionBoundsPrefix];

    //[self addCallMethodRule:@selector(addBound:) forPrefix:[self extendPrefix:prefix withValue:@"bounds/[]"]];

    [self addSetPropertyRule:@"supportsObaDiscoveryApis" forPrefix:[self extendPrefix:prefix withValue:@"supportsObaDiscoveryApis"]];
    [self addSetPropertyRule:@"contactEmail" forPrefix:[self extendPrefix:prefix withValue:@"contactEmail"]];
    [self addSetPropertyRule:@"twitterUrl" forPrefix:[self extendPrefix:prefix withValue:@"twitterUrl"]];
    [self addSetPropertyRule:@"facebookUrl" forPrefix:[self extendPrefix:prefix withValue:@"facebookUrl"]];
    [self addSetPropertyRule:@"active" forPrefix:[self extendPrefix:prefix withValue:@"active"]];
    [self addSetPropertyRule:@"experimental" forPrefix:[self extendPrefix:prefix withValue:@"experimental"]];
    [self addSetPropertyRule:@"obaBaseUrl" forPrefix:[self extendPrefix:prefix withValue:@"obaBaseUrl"]];
    [self addSetPropertyRule:@"id_number" forPrefix:[self extendPrefix:prefix withValue:@"id"]];
    [self addSetPropertyRule:@"regionName" forPrefix:[self extendPrefix:prefix withValue:@"regionName"]];
}

- (void) addRegionBoundsV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBARegionBoundsV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"lat" forPrefix:[self extendPrefix:prefix withValue:@"lat"]];
    [self addSetPropertyRule:@"latSpan" forPrefix:[self extendPrefix:prefix withValue:@"latSpan"]];
    [self addSetPropertyRule:@"lon" forPrefix:[self extendPrefix:prefix withValue:@"lon"]];
    [self addSetPropertyRule:@"lonSpan" forPrefix:[self extendPrefix:prefix withValue:@"lonSpan"]];
}

- (void) addTripStatusV2RulesWithPrefix:(NSString*)prefix {
    
    [self addObjectCreateRule:[OBATripStatusV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"activeTripId" forPrefix:[self extendPrefix:prefix withValue:@"activeTripId"]];
    [self addSetPropertyRule:@"serviceDate" forPrefix:[self extendPrefix:prefix withValue:@"serviceDate"]];

    NSString * frequencyPrefix = [self extendPrefix:prefix withValue:@"frequency"];
    [self addFrequencyV2RulesWithPrefix:frequencyPrefix];
    [self addSetNext:@selector(setFrequency:) forPrefix:frequencyPrefix];
    
    [self addSetLocationPropertyRule:@"location" withPrefix:[self extendPrefix:prefix withValue:@"position"]];
    [self addSetPropertyRule:@"predicted" forPrefix:[self extendPrefix:prefix withValue:@"predicted"]];
    [self addSetPropertyRule:@"scheduleDeviation" forPrefix:[self extendPrefix:prefix withValue:@"scheduleDeviation"]];
    [self addSetPropertyRule:@"vehicleId" forPrefix:[self extendPrefix:prefix withValue:@"vehicleId"]];
    
    [self addSetPropertyRule:@"lastUpdateTime" forPrefix:[self extendPrefix:prefix withValue:@"lastUpdateTime"]];
    [self addSetLocationPropertyRule:@"lastKnownLocation" withPrefix:[self extendPrefix:prefix withValue:@"lastKnownLocation"]];
    [self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
}         

- (void) addFrequencyV2RulesWithPrefix:(NSString*)prefix {
    
    [self addObjectCreateRule:[OBAFrequencyV2 class] forPrefix:prefix];
    
    [self addSetPropertyRule:@"startTime" forPrefix:[self extendPrefix:prefix withValue:@"startTime"]];
    [self addSetPropertyRule:@"endTime" forPrefix:[self extendPrefix:prefix withValue:@"endTime"]];
    [self addSetPropertyRule:@"headway" forPrefix:[self extendPrefix:prefix withValue:@"headway"]];
}

- (void) addCurrentVehicleEstimateV2RulesWithPrefix:(NSString*)prefix {

    [self addObjectCreateRule:[OBACurrentVehicleEstimateV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"probability" forPrefix:[self extendPrefix:prefix withValue:@"probability"]];
    [self addSetPropertyRule:@"debug" forPrefix:[self extendPrefix:prefix withValue:@"debug"]];
    
    NSString * tripStatusPrefix = [self extendPrefix:prefix withValue:@"tripStatus"];
    [self addTripStatusV2RulesWithPrefix:tripStatusPrefix];
    [self addSetNext:@selector(setTripStatus:) forPrefix:tripStatusPrefix];    
}

- (void) addVehicleStatusV2RulesWithPrefix:(NSString*)prefix {
    [self addObjectCreateRule:[OBAVehicleStatusV2 class] forPrefix:prefix];
    [self addSetPropertyRule:@"vehicleId" forPrefix:[self extendPrefix:prefix withValue:@"vehicleId"]];
    [self addSetPropertyRule:@"lastUpdateTime" forPrefix:[self extendPrefix:prefix withValue:@"lastUpdateTime"]];    

    NSString * tripStatusPrefix = [self extendPrefix:prefix withValue:@"tripStatus"];
    [self addTripStatusV2RulesWithPrefix:tripStatusPrefix];
    [self addSetNext:@selector(setTripStatus:) forPrefix:tripStatusPrefix];    
}

- (void) addAgencyToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    OBAAgencyV2 * agency = [context peek:0];
    OBAReferencesV2 * refs = [context getParameterForKey:kReferences];
    [refs addAgency:agency];
    agency.references = refs;
}

- (void) addRouteToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    OBARouteV2 * route = [context peek:0];
    OBAReferencesV2 * refs = [context getParameterForKey:kReferences];
    [refs addRoute:route];
    route.references = refs;
}

- (void) addStopToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    OBAStopV2 * stop = [context peek:0];
    OBAReferencesV2 * refs = [context getParameterForKey:kReferences];
    [refs addStop:stop];
    stop.references = refs;
}

- (void) addTripToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    OBATripV2 * trip = [context peek:0];
    OBAReferencesV2 * refs = [context getParameterForKey:kReferences];
    [refs addTrip:trip];
    trip.references = refs;
}
                                    
- (void) addSituationToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    OBASituationV2 * situation = [context peek:0];
    OBAReferencesV2 * refs = [context getParameterForKey:kReferences];
    [refs addSituation:situation];
    situation.references = refs;
    
}
                                        

- (void) setReferencesForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    OBAHasReferencesV2 * top = [context peek:0];
    OBAReferencesV2 * refs = [context getParameterForKey:kReferences];
    top.references = refs;
}

- (void) addSetCoordinatePropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix method:(OBASetCoordinatePropertyMethod)method {
    OBASetCoordinatePropertyJsonDigesterRule * rule = [[OBASetCoordinatePropertyJsonDigesterRule alloc] initWithPropertyName:propertyName method:method];
    [self addRule:rule forPrefix:prefix];
}

- (void) addSetLocationPropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix {
    OBASetLocationPropertyJsonDigesterRule * rule = [[OBASetLocationPropertyJsonDigesterRule alloc] initWithPropertyName:propertyName];
    [self addRule:rule forPrefix:prefix];
}

- (void) addSetDatePropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix {
    OBASetDatePropertyJsonDigesterRule * rule = [[OBASetDatePropertyJsonDigesterRule alloc] initWithPropertyName:propertyName];
    [self addRule:rule forPrefix:prefix];
}

@end 


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
#import "OBACommon.h"

#import "OBAAgency.h"
#import "OBARoute.h"
#import "OBAStop.h"
#import "OBAStopPreferences.h"
#import "OBAArrivalAndDeparture.h"
#import "OBAArrivalsAndDeparturesForStop.h"
#import "OBAPlacemark.h"
#import "OBAAgencyWithCoverage.h"
#import "OBATrip.h"
#import "OBATripStatus.h"

#import "OBAReferencesV2.h"
#import "OBAAgencyV2.h"
#import "OBARouteV2.h"
#import "OBAStopV2.h"
#import "OBAAgencyWithCoverageV2.h"

#import "OBAJsonDigester.h"
#import "OBASetCoordinatePropertyJsonDigesterRule.h"
#import "OBASetLocationPropertyJsonDigesterRule.h"
#import "OBACreateManagedEntityJsonDigesterRule.h"
#import "OBAEntityManager.h"


static NSString * const kOBAAgency = @"OBAAgency";
static NSString * const kOBARoute = @"OBARoute";
static NSString * const kOBAStop = @"OBAStop";
static NSString * const kOBAStopPreferences = @"OBAStopPreferences";

static NSString * const kManagedObjectContext = @"managedObjectContext";
static NSString * const kEntityIdMappings = @"entityIdMappings";


@interface OBAModelFactory (Private)

- (NSDictionary*) getDigesterParameters;

@end


@interface OBAJsonDigester (CustomDigesterRules)

//- (void) addListWithRangeRulesWithPrefix:(NSString*)prefix;
- (void) addReferencesRulesWithPrefix:(NSString*)prefix;

- (void) addAgencyRulesWithPrefix:(NSString*)prefix;
- (void) addRouteRulesWithPrefix:(NSString*)prefix;
- (void) addStopRulesWithPrefix:(NSString*)prefix;
- (void) addTripRulesWithPrefix:(NSString*)prefix;
- (void) addTripStatusRulesWithPrefix:(NSString*)prefix;
- (void) addArrivalAndDepartureRulesWithPrefix:(NSString*)prefix;

- (void) addAgencyV2RulesWithPrefix:(NSString*)prefix;
- (void) addRouteV2RulesWithPrefix:(NSString*)prefix;
- (void) addStopV2RulesWithPrefix:(NSString*)prefix;

- (void) addAgencyWithCoverageV2RulesWithPrefix:(NSString*)prefix;

- (void) addArrivalAndDepartureV2RulesWithPrefix:(NSString*)prefix;

- (void) setReferencesFromParentForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;

- (void) addSetCoordinatePropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix method:(OBASetCoordinatePropertyMethod)method;
- (void) addSetLocationPropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix;

@end


@implementation OBAModelFactory

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	if( self = [super init] ) {
		_context = [managedObjectContext retain];
		_entityIdMappings = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_context release];
	[_entityIdMappings release];
	[super dealloc];
}

/*
- (NSArray*) getStopsFromJSONArray:(NSArray*)jsonArray error:(NSError**)error {
	
	NSMutableArray * results = [NSMutableArray array];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addStopRulesWithPrefix:@"/[]"];
	[digester addSetNext:@selector(addObject:) forPrefix:@"/[]"];
	[digester addTarget:digester selector:@selector(saveIfNeededForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:@"/"];
	[digester parse:jsonArray withRoot:results parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return results;
}
*/

- (NSArray*) getRoutesFromJSONArray:(NSArray*)jsonArray error:(NSError**)error {
	
	NSMutableArray * results = [NSMutableArray array];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addRouteRulesWithPrefix:@"/[]"];
	[digester addSetNext:@selector(addObject:) forPrefix:@"/[]"];
	[digester addTarget:digester selector:@selector(saveIfNeededForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:@"/"];
	[digester parse:jsonArray withRoot:results parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return results;
}

- (NSArray*) getPlacemarksFromJSONObject:(id)jsonObject error:(NSError**)error {
	
	NSMutableArray * placemarks = [NSMutableArray array];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addObjectCreateRule:[OBAPlacemark class] forPrefix:@"/Placemark/[]"];
	[digester addSetPropertyRule:@"address" forPrefix:@"/Placemark/[]/address"];
	[digester addSetNext:@selector(addObject:) forPrefix:@"/Placemark/[]"];
	
	OBASetCoordinatePropertyJsonDigesterRule * rule = [[OBASetCoordinatePropertyJsonDigesterRule alloc] initWithPropertyName:@"coordinate"];
	[digester addRule:rule forPrefix:@"/Placemark/[]/Point/coordinates"];
	[rule release];
	
	[digester parse:jsonObject withRoot:placemarks parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return placemarks;
}

- (NSArray*) getAgenciesWithCoverageFromJson:(id)jsonArray error:(NSError**)error {

	NSMutableArray * results = [NSMutableArray array];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addObjectCreateRule:[OBAAgencyWithCoverage class] forPrefix:@"/[]"];
	[digester addAgencyRulesWithPrefix:@"/[]/agency"];
	[digester addSetNext:@selector(setAgency:) forPrefix:@"/[]/agency"];
	[digester addSetCoordinatePropertyRule:@"coordinate" withPrefix:@"/[]" method:OBASetCoordinatePropertyMethodLatLon];
	[digester addSetNext:@selector(addObject:) forPrefix:@"/[]"];
	[digester addTarget:digester selector:@selector(saveIfNeededForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:@"/"];
	
	[digester parse:jsonArray withRoot:results parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return results;
}

- (NSArray*) getTripStatusElementsFromJSONArray:(NSArray*)jsonArray error:(NSError**)error {
	
	NSMutableArray * results = [NSMutableArray array];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addTripStatusRulesWithPrefix:@"/[]"];
	[digester addSetNext:@selector(addObject:) forPrefix:@"/[]"];
	[digester addTarget:digester selector:@selector(saveIfNeededForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:@"/"];
	
	[digester parse:jsonArray withRoot:results parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return results;
}

- (OBAArrivalsAndDeparturesForStop*) getArrivalsAndDeparturesForStopFromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
	
	OBAArrivalsAndDeparturesForStop * ads = [[[OBAArrivalsAndDeparturesForStop alloc] init] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addStopRulesWithPrefix:@"/stop"];
	[digester addSetNext:@selector(setStop:) forPrefix:@"/stop"];
	[digester addObjectCreateRule:[NSMutableArray class] forPrefix:@"/arrivalsAndDepartures"];
	[digester addSetNext:@selector(setArrivalsAndDepartures:) forPrefix:@"/arrivalsAndDepartures"];
	[digester addArrivalAndDepartureRulesWithPrefix:@"/arrivalsAndDepartures/[]"];
	[digester addSetNext:@selector(addObject:) forPrefix:@"/arrivalsAndDepartures/[]"];	
	[digester addTarget:digester selector:@selector(saveIfNeededForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:@"/"];
	
	[digester parse:jsonDictionary withRoot:ads parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return ads;
}

- (OBAListWithRangeAndReferencesV2*) getStopsV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
	
	OBAListWithRangeAndReferencesV2 * list = [[[OBAListWithRangeAndReferencesV2 alloc] init] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addSetNext:@selector(setReferences:) forPrefix:@"/references"];
	[digester addSetPropertyRule:@"outOfRange" forPrefix:@"/outOfRange"];
	[digester addSetPropertyRule:@"limitExceeded" forPrefix:@"/limitExceeded"];
	[digester addStopV2RulesWithPrefix:@"/list/[]"];
	[digester addTarget:digester selector:@selector(setReferencesFromParentForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:@"/list/[]"];
	[digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
	
	[digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return list;
}

- (OBAListWithRangeAndReferencesV2*) getRoutesV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
	
	OBAListWithRangeAndReferencesV2 * list = [[[OBAListWithRangeAndReferencesV2 alloc] init] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addSetNext:@selector(setReferences:) forPrefix:@"/references"];
	[digester addRouteV2RulesWithPrefix:@"/list/[]"];
	[digester addTarget:digester selector:@selector(setReferencesFromParentForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:@"/list/[]"];
	[digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
	
	[digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return list;
}

- (OBAStopsForRouteV2*) getStopsForRouteV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {

	OBAStopsForRouteV2 * result = [[[OBAStopsForRouteV2 alloc] init] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addSetNext:@selector(setReferences:) forPrefix:@"/references"];
	[digester addCallMethodRule:@selector(addStopId:) forPrefix:@"/entry/stopIds/[]"];
	[digester parse:jsonDictionary withRoot:result parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return result;
}

- (OBAListWithRangeAndReferencesV2*) getAgenciesWithCoverageV2FromJson:(id)jsonDictionary error:(NSError**)error {
	
	OBAListWithRangeAndReferencesV2 * list = [[[OBAListWithRangeAndReferencesV2 alloc] init] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addSetNext:@selector(setReferences:) forPrefix:@"/references"];
	[digester addAgencyWithCoverageV2RulesWithPrefix:@"/list/[]"];
	[digester addTarget:digester selector:@selector(setReferencesFromParentForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:@"/list/[]"];
	[digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
	
	[digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return list;
}

- (OBAArrivalsAndDeparturesForStopV2*) getArrivalsAndDeparturesForStopV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {

	OBAArrivalsAndDeparturesForStopV2 * ads = [[[OBAArrivalsAndDeparturesForStopV2 alloc] init] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addSetNext:@selector(setReferences:) forPrefix:@"/references"];
	[digester addSetPropertyRule:@"stopId" forPrefix:@"/entry/stopId"];
	[digester addArrivalAndDepartureV2RulesWithPrefix:@"/entry/arrivalsAndDepartures/[]"];
	[digester addTarget:digester selector:@selector(setReferencesFromParentForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:@"/entry/arrivalsAndDepartures/[]"];
	[digester addSetNext:@selector(addArrivalAndDeparture:) forPrefix:@"/entry/arrivalsAndDepartures/[]"];	
	
	[digester parse:jsonDictionary withRoot:ads parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return ads;
}

@end

@implementation OBAModelFactory (Private)

- (NSDictionary*) getDigesterParameters {
	NSMutableDictionary * params = [NSMutableDictionary dictionary];
	//[params setObject:_entityIdMappings forKey:kEntityIdMappings];
	//[params setObject:_context forKey:kManagedObjectContext];
	return params;
}

@end

	
@implementation OBAJsonDigester (CustomDigesterRules)

- (void) addAgencyRulesWithPrefix:(NSString*)prefix {

	OBACreateManagedEntityJsonDigesterRule * rule = [[OBACreateManagedEntityJsonDigesterRule alloc] initWithEntityName:kOBAAgency entityIdProperty:@"agencyId" jsonIdProperty:@"id"];
	[self addRule:rule forPrefix:prefix];
	[rule release];
	
	[self addSetPropertyIfNeededRule:@"name" forPrefix:[self extendPrefix:prefix withValue:@"name"]];
	[self addSetPropertyIfNeededRule:@"url" forPrefix:[self extendPrefix:prefix withValue:@"url"]];
}

- (void) addRouteRulesWithPrefix:(NSString*)prefix {
	
	OBACreateManagedEntityJsonDigesterRule * rule = [[OBACreateManagedEntityJsonDigesterRule alloc] initWithEntityName:kOBARoute entityIdProperty:@"routeId" jsonIdProperty:@"id"];
	[self addRule:rule forPrefix:prefix];
	[rule release];

	[self addSetPropertyIfNeededRule:@"shortName" forPrefix:[self extendPrefix:prefix withValue:@"shortName"]];
	[self addSetPropertyIfNeededRule:@"longName" forPrefix:[self extendPrefix:prefix withValue:@"longName"]];
	[self addSetPropertyIfNeededRule:@"routeType" forPrefix:[self extendPrefix:prefix withValue:@"type"]];

	[self addAgencyRulesWithPrefix:[self extendPrefix:prefix withValue:@"agency"]];
	[self addTarget:self selector:@selector(setRouteAgencyIfNeededForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:[self extendPrefix:prefix withValue:@"agency"]];
}

- (void) addStopRulesWithPrefix:(NSString*)prefix {
	
	OBACreateManagedEntityJsonDigesterRule * rule = [[OBACreateManagedEntityJsonDigesterRule alloc] initWithEntityName:kOBAStop entityIdProperty:@"stopId" jsonIdProperty:@"id"];
	[self addRule:rule forPrefix:prefix];
	[rule release];

	[self addSetPropertyIfNeededRule:@"name" forPrefix:[self extendPrefix:prefix withValue:@"name"]];
	[self addSetPropertyIfNeededRule:@"code" forPrefix:[self extendPrefix:prefix withValue:@"code"]]; // Optional
	[self addSetPropertyIfNeededRule:@"direction" forPrefix:[self extendPrefix:prefix withValue:@"direction"]]; // Optional
	[self addSetPropertyIfNeededRule:@"latitude" forPrefix:[self extendPrefix:prefix withValue:@"lat"]];
	[self addSetPropertyIfNeededRule:@"longitude" forPrefix:[self extendPrefix:prefix withValue:@"lon"]];
	[self addTarget:self selector:@selector(ensureStopPreferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:prefix];
	
	[self addObjectCreateRule:[NSMutableArray class] forPrefix:[self extendPrefix:prefix withValue:@"routes"]];
	[self addTarget:self selector:@selector(setStopRoutesIfNeededForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:[self extendPrefix:prefix withValue:@"routes"]];
	
	[self addRouteRulesWithPrefix:[self extendPrefix:prefix withValue:@"routes/[]"]];
	[self addSetNext:@selector(addObject:) forPrefix:[self extendPrefix:prefix withValue:@"routes/[]"]];
}

- (void) addTripRulesWithPrefix:(NSString*)prefix {
	
	[self addObjectCreateRule:[OBATrip class] forPrefix:prefix];
	
	[self addSetPropertyRule:@"tripId" forPrefix:[self extendPrefix:prefix withValue:@"id"]];
	[self addSetPropertyRule:@"tripHeadsign" forPrefix:[self extendPrefix:prefix withValue:@"tripHeadsign"]];
	[self addSetPropertyRule:@"routeShortName" forPrefix:[self extendPrefix:prefix withValue:@"routeShortName"]];
}

- (void) addTripStatusRulesWithPrefix:(NSString*)prefix {
	
	[self addObjectCreateRule:[OBATripStatus class] forPrefix:prefix];
	[self addTripRulesWithPrefix:[self extendPrefix:prefix withValue:@"trip"]];
	[self addSetNext:@selector(setTrip:) forPrefix:[self extendPrefix:prefix withValue:@"trip"]];
	[self addRouteRulesWithPrefix:[self extendPrefix:prefix withValue:@"route"]];
	[self addSetNext:@selector(setRoute:) forPrefix:[self extendPrefix:prefix withValue:@"route"]];
	[self addSetLocationPropertyRule:@"position" withPrefix:[self extendPrefix:prefix withValue:@"position"]];
	[self addSetPropertyRule:@"serviceDate" forPrefix:[self extendPrefix:prefix withValue:@"serviceDate"]];
	[self addSetPropertyRule:@"scheduleDeviation" forPrefix:[self extendPrefix:prefix withValue:@"scheduleDeviation"]];
	[self addSetPropertyRule:@"predicted" forPrefix:[self extendPrefix:prefix withValue:@"predicted"]];
	[self addTarget:self selector:@selector(ensureArrivalAndDepartureRouteForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:[self extendPrefix:prefix withValue:@"routeId"]];
}

- (void) addArrivalAndDepartureRulesWithPrefix:(NSString*)prefix {
	
	[self addObjectCreateRule:[OBAArrivalAndDeparture class] forPrefix:prefix];
	
	[self addSetPropertyRule:@"routeShortName" forPrefix:[self extendPrefix:prefix withValue:@"routeShortName"]];
	[self addSetPropertyRule:@"tripId" forPrefix:[self extendPrefix:prefix withValue:@"tripId"]];
	[self addSetPropertyRule:@"tripHeadsign" forPrefix:[self extendPrefix:prefix withValue:@"tripHeadsign"]];

	[self addSetPropertyRule:@"scheduledArrivalTime" forPrefix:[self extendPrefix:prefix withValue:@"scheduledArrivalTime"]];
	[self addSetPropertyRule:@"predictedArrivalTime" forPrefix:[self extendPrefix:prefix withValue:@"predictedArrivalTime"]];
	[self addSetPropertyRule:@"scheduledDepartureTime" forPrefix:[self extendPrefix:prefix withValue:@"scheduledDepartureTime"]];
	[self addSetPropertyRule:@"predictedDepartureTime" forPrefix:[self extendPrefix:prefix withValue:@"predictedDepartureTime"]];
	
	[self addTarget:self selector:@selector(ensureArrivalAndDepartureRouteForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:[self extendPrefix:prefix withValue:@"routeId"]];
}

- (void) addReferencesRulesWithPrefix:(NSString*)prefix {
	
	[self addObjectCreateRule:[OBAReferencesV2 class] forPrefix:prefix];
	[self addSetNext:@selector(setReferences:) forPrefix:prefix];
	
	NSString * agencyPrefix = [self extendPrefix:prefix withValue:@"agencies/[]"];
	[self addAgencyV2RulesWithPrefix:agencyPrefix];
	[self addTarget:self selector:@selector(setReferencesFromParentForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:agencyPrefix];
	[self addSetNext:@selector(addAgency:) forPrefix:agencyPrefix];	

	NSString * routePrefix = [self extendPrefix:prefix withValue:@"routes/[]"];
	[self addRouteV2RulesWithPrefix:routePrefix];
	[self addTarget:self selector:@selector(setReferencesFromParentForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:routePrefix];
	[self addSetNext:@selector(addRoute:) forPrefix:routePrefix];
	
	NSString * stopPrefix = [self extendPrefix:prefix withValue:@"stops/[]"];
	[self addStopV2RulesWithPrefix:stopPrefix];
	[self addTarget:self selector:@selector(setReferencesFromParentForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetBegin prefix:stopPrefix];
	[self addSetNext:@selector(addStop:) forPrefix:stopPrefix];	
	

}

- (void) addAgencyV2RulesWithPrefix:(NSString*)prefix {	
	[self addObjectCreateRule:[OBAAgencyV2 class] forPrefix:prefix];
	[self addSetPropertyRule:@"agencyId" forPrefix:[self extendPrefix:prefix withValue:@"id"]];
	[self addSetPropertyRule:@"name" forPrefix:[self extendPrefix:prefix withValue:@"name"]];
	[self addSetPropertyRule:@"url" forPrefix:[self extendPrefix:prefix withValue:@"url"]];	
}

- (void) addRouteV2RulesWithPrefix:(NSString*)prefix {	
	[self addObjectCreateRule:[OBARouteV2 class] forPrefix:prefix];
	[self addSetPropertyRule:@"routeId" forPrefix:[self extendPrefix:prefix withValue:@"id"]];
	[self addSetPropertyRule:@"shortName" forPrefix:[self extendPrefix:prefix withValue:@"shortName"]];
	[self addSetPropertyRule:@"longName" forPrefix:[self extendPrefix:prefix withValue:@"longName"]];
	[self addSetPropertyRule:@"routeType" forPrefix:[self extendPrefix:prefix withValue:@"type"]];
	[self addSetPropertyRule:@"agencyId" forPrefix:[self extendPrefix:prefix withValue:@"agencyId"]];
}

- (void) addStopV2RulesWithPrefix:(NSString*)prefix {
	[self addObjectCreateRule:[OBAStopV2 class] forPrefix:prefix];
	[self addSetPropertyRule:@"stopId" forPrefix:[self extendPrefix:prefix withValue:@"id"]];	
	[self addSetPropertyRule:@"name" forPrefix:[self extendPrefix:prefix withValue:@"name"]];
	[self addSetPropertyRule:@"code" forPrefix:[self extendPrefix:prefix withValue:@"code"]]; // Optional
	[self addSetPropertyRule:@"direction" forPrefix:[self extendPrefix:prefix withValue:@"direction"]]; // Optional
	[self addSetPropertyRule:@"latitude" forPrefix:[self extendPrefix:prefix withValue:@"lat"]];
	[self addSetPropertyRule:@"longitude" forPrefix:[self extendPrefix:prefix withValue:@"lon"]];
	[self addSetPropertyRule:@"routeIds" forPrefix:[self extendPrefix:prefix withValue:@"routeIds"]];
}

- (void) addAgencyWithCoverageV2RulesWithPrefix:(NSString*)prefix {
	[self addObjectCreateRule:[OBAAgencyWithCoverageV2 class] forPrefix:prefix];
	[self addSetPropertyRule:@"agencyId" forPrefix:[self extendPrefix:prefix withValue:@"agencyId"]];	
	[self addSetCoordinatePropertyRule:@"coordinate" withPrefix:prefix method:OBASetCoordinatePropertyMethodLatLon];
}

- (void) addArrivalAndDepartureV2RulesWithPrefix:(NSString*)prefix {
	
	[self addObjectCreateRule:[OBAArrivalAndDepartureV2 class] forPrefix:prefix];
	
	[self addSetPropertyRule:@"routeId" forPrefix:[self extendPrefix:prefix withValue:@"routeId"]];
	[self addSetPropertyRule:@"routeShortName" forPrefix:[self extendPrefix:prefix withValue:@"routeShortName"]];
	
	[self addSetPropertyRule:@"tripId" forPrefix:[self extendPrefix:prefix withValue:@"tripId"]];
	[self addSetPropertyRule:@"tripHeadsign" forPrefix:[self extendPrefix:prefix withValue:@"tripHeadsign"]];
	
	[self addSetPropertyRule:@"stopId" forPrefix:[self extendPrefix:prefix withValue:@"stopId"]];
	
	[self addSetPropertyRule:@"scheduledArrivalTime" forPrefix:[self extendPrefix:prefix withValue:@"scheduledArrivalTime"]];
	[self addSetPropertyRule:@"predictedArrivalTime" forPrefix:[self extendPrefix:prefix withValue:@"predictedArrivalTime"]];
	[self addSetPropertyRule:@"scheduledDepartureTime" forPrefix:[self extendPrefix:prefix withValue:@"scheduledDepartureTime"]];
	[self addSetPropertyRule:@"predictedDepartureTime" forPrefix:[self extendPrefix:prefix withValue:@"predictedDepartureTime"]];
}

- (void) setReferencesFromParentForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	OBAHasReferencesV2 * top = [context peek:0];
    id parent = [context peek:1];
	if( [parent isKindOfClass:[OBAReferencesV2 class]] )
		top.references = parent;
	else if( [parent isKindOfClass:[OBAHasReferencesV2 class]] ) {
		OBAHasReferencesV2 * p = (OBAHasReferencesV2*) parent;
		OBAReferencesV2 * refs = p.references;
		top.references = refs;
	}
}

- (void) addSetCoordinatePropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix method:(OBASetCoordinatePropertyMethod)method {
	OBASetCoordinatePropertyJsonDigesterRule * rule = [[OBASetCoordinatePropertyJsonDigesterRule alloc] initWithPropertyName:propertyName method:method];
	[self addRule:rule forPrefix:prefix];
	[rule release];
}

- (void) addSetLocationPropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix {
	OBASetLocationPropertyJsonDigesterRule * rule = [[OBASetLocationPropertyJsonDigesterRule alloc] initWithPropertyName:propertyName];
	[self addRule:rule forPrefix:prefix];
	[rule release];	
}

- (void) setRouteAgencyIfNeededForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	OBAAgency * agency = [context peek:0];
	OBARoute * route = [context peek:1];
	if( ! [route.agency isEqual:agency] )
		route.agency = agency;
}

- (void) setStopRoutesIfNeededForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	
	NSArray * routes = [context peek:0];
	OBAStop * stop = [context peek:1];
	
	NSMutableDictionary * originalRoutes = [NSMutableDictionary dictionary];
	NSMutableDictionary * newRoutes = [NSMutableDictionary dictionary];
		
	for ( OBARoute * route in stop.routes )
		[originalRoutes setObject:route forKey:route.routeId];
	for( OBARoute * route in routes)
		[newRoutes setObject:route forKey:route.routeId];
		
	for( NSString * routeId in newRoutes ) {
		if( ! [originalRoutes objectForKey:routeId] )
			[stop addRoutesObject:[newRoutes objectForKey:routeId]];
	}
	
	for( NSString * routeId in originalRoutes) {
		if( ! [newRoutes objectForKey:routeId] )
			[stop removeRoutesObject:[originalRoutes objectForKey:routeId]];
	}
}

- (void) ensureStopPreferencesForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	OBAStop * stop = [context peek:0];
	if( stop.preferences == nil ) {
		NSManagedObjectContext * managedObjectContext = [context getParameterForKey:kManagedObjectContext];
		OBAStopPreferences * prefs = [NSEntityDescription insertNewObjectForEntityForName:kOBAStopPreferences inManagedObjectContext:managedObjectContext];
		stop.preferences = prefs;
	}
}

- (void) ensureArrivalAndDepartureRouteForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {

	OBAArrivalAndDeparture * arrivalAndDeparture = [context peek:0];
	NSString * routeId = value;
	
	NSError * error = nil;
	NSManagedObjectContext * managedObjectContext = [context getParameterForKey:kManagedObjectContext];
	NSMutableDictionary * entityIdMappings = [context getParameterForKey:kEntityIdMappings];
	
	arrivalAndDeparture.route = [OBAEntityManager getEntityWithName:kOBARoute entityIdProperty:@"routeId" entityId:routeId fromContext:managedObjectContext withEntityIdMappings:entityIdMappings error:&error];
	
	if( error ) {
		context.error = error;
		return;
	}
}

- (void) saveIfNeededForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	
	NSManagedObjectContext * managedObjectContext = [context getParameterForKey:kManagedObjectContext];
	NSMutableDictionary * entityIdMappings = [context getParameterForKey:kEntityIdMappings];
	
	NSError * error = nil;
	
	
	if( [managedObjectContext hasChanges] ) {
		if( context.verbose)
			OBALogDebug(@"saving managedObjectContext");
		
		@try {
			[managedObjectContext save:&error];
		}
		@catch (NSException * e) {
			OBALogSevere(@"Exception caught: name=%@ reason=%@",[e name],[e reason]);
			@throw e;
		}
		@catch (id unknown) {
			OBALogSevere(@"Exception caught: desc=%@",[unknown description]);
			@throw unknown;
		}
		
		[entityIdMappings removeAllObjects];
		if( context.verbose)
			OBALogDebug(@"saved managedObjectContext");
	}
	
	if( error ) {
		OBALogSevereWithError(error,@"Error saving managedObjectContext");
		context.error = error;
		return;
	}
}	

@end 


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

#import "OBAReferencesV2.h"
#import "OBAAgencyV2.h"
#import "OBARouteV2.h"
#import "OBAStopV2.h"
#import "OBATripV2.h"
#import "OBATripDetailsV2.h"
#import "OBATripScheduleV2.h"
#import "OBATripStopTimeV2.h"

#import "OBAAgencyWithCoverageV2.h"
#import "OBAPlacemark.h"

#import "OBAJsonDigester.h"
#import "OBASetCoordinatePropertyJsonDigesterRule.h"
#import "OBASetLocationPropertyJsonDigesterRule.h"


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
- (void) addTripDetailsV2RulesWithPrefix:(NSString*)prefix;

- (void) addAgencyWithCoverageV2RulesWithPrefix:(NSString*)prefix;

- (void) addArrivalAndDepartureV2RulesWithPrefix:(NSString*)prefix;

- (void) addAgencyToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) addRouteToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) addStopToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) addTripToReferences:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;

- (void) setReferencesForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;

- (void) addSetCoordinatePropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix method:(OBASetCoordinatePropertyMethod)method;
- (void) addSetLocationPropertyRule:(NSString*)propertyName withPrefix:(NSString*)prefix;

@end


@implementation OBAModelFactory

- (id) initWithReferences:(OBAReferencesV2*)references {
	
	if( self = [super init] ) {
		_references = [references retain];
		_entityIdMappings = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_references release];
	[_entityIdMappings release];
	[super dealloc];
}

- (OBAEntryWithReferencesV2*) getStopFromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {

	OBAEntryWithReferencesV2 * entry = [[[OBAEntryWithReferencesV2 alloc] initWithReferences:_references] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addStopV2RulesWithPrefix:@"/entry"];
	[digester addSetNext:@selector(setEntry:) forPrefix:@"/entry"];
	
	[digester parse:jsonDictionary withRoot:entry parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return entry;
}

- (OBAListWithRangeAndReferencesV2*) getStopsV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
	
	OBAListWithRangeAndReferencesV2 * list = [[[OBAListWithRangeAndReferencesV2 alloc] initWithReferences:_references] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addSetPropertyRule:@"outOfRange" forPrefix:@"/outOfRange"];
	[digester addSetPropertyRule:@"limitExceeded" forPrefix:@"/limitExceeded"];
	[digester addStopV2RulesWithPrefix:@"/list/[]"];
	[digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
	
	[digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return list;
}

- (OBAListWithRangeAndReferencesV2*) getRoutesV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {
	
	OBAListWithRangeAndReferencesV2 * list = [[[OBAListWithRangeAndReferencesV2 alloc] initWithReferences:_references] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addRouteV2RulesWithPrefix:@"/list/[]"];
	[digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
	
	[digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return list;
}

- (OBAStopsForRouteV2*) getStopsForRouteV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {

	OBAStopsForRouteV2 * result = [[[OBAStopsForRouteV2 alloc] initWithReferences:_references] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addCallMethodRule:@selector(addStopId:) forPrefix:@"/entry/stopIds/[]"];
	[digester parse:jsonDictionary withRoot:result parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return result;
}

- (OBAListWithRangeAndReferencesV2*) getAgenciesWithCoverageV2FromJson:(id)jsonDictionary error:(NSError**)error {
	
	OBAListWithRangeAndReferencesV2 * list = [[[OBAListWithRangeAndReferencesV2 alloc] initWithReferences:_references] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addAgencyWithCoverageV2RulesWithPrefix:@"/list/[]"];
	[digester addSetNext:@selector(addValue:) forPrefix:@"/list/[]"];
	
	[digester parse:jsonDictionary withRoot:list parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return list;
}

- (OBAArrivalsAndDeparturesForStopV2*) getArrivalsAndDeparturesForStopV2FromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error {

	[_references clear];
	
	OBAArrivalsAndDeparturesForStopV2 * ads = [[[OBAArrivalsAndDeparturesForStopV2 alloc] initWithReferences:_references] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addSetPropertyRule:@"stopId" forPrefix:@"/entry/stopId"];
	[digester addArrivalAndDepartureV2RulesWithPrefix:@"/entry/arrivalsAndDepartures/[]"];
	[digester addSetNext:@selector(addArrivalAndDeparture:) forPrefix:@"/entry/arrivalsAndDepartures/[]"];	
	
	[digester parse:jsonDictionary withRoot:ads parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return ads;
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

- (OBAEntryWithReferencesV2*) getTripDetailsV2FromJSON:(NSDictionary*)json error:(NSError**)error {

	OBAEntryWithReferencesV2 * entry = [[[OBAEntryWithReferencesV2 alloc] initWithReferences:_references] autorelease];
	
	OBAJsonDigester * digester = [[OBAJsonDigester alloc] init];
	[digester addReferencesRulesWithPrefix:@"/references"];
	[digester addTripDetailsV2RulesWithPrefix:@"/entry"];
	[digester addSetNext:@selector(setEntry:) forPrefix:@"/entry"];
	
	[digester parse:json withRoot:entry parameters:[self getDigesterParameters] error:error];
	[digester release];
	
	return entry;
}

@end

@implementation OBAModelFactory (Private)

- (NSDictionary*) getDigesterParameters {
	NSMutableDictionary * params = [NSMutableDictionary dictionary];
	[params setObject:_references forKey:kReferences];
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
	[self addSetPropertyRule:@"direction" forPrefix:[self extendPrefix:prefix withValue:@"direction"]]; // Optional
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
	[self addSetPropertyRule:@"shapeId" forPrefix:[self extendPrefix:prefix withValue:@"shapeId"]];
	[self addSetPropertyRule:@"directionId" forPrefix:[self extendPrefix:prefix withValue:@"directionId"]];
	[self addTarget:self selector:@selector(addTripToReferences:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];	
}

- (void) addTripDetailsV2RulesWithPrefix:(NSString*)prefix {
	[self addObjectCreateRule:[OBATripDetailsV2 class] forPrefix:prefix];
	[self addSetPropertyRule:@"tripId" forPrefix:[self extendPrefix:prefix withValue:@"tripId"]];
	[self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
	
	NSString * schedulePrefix = [self extendPrefix:prefix withValue:@"schedule"];
	[self addObjectCreateRule:[OBATripScheduleV2 class] forPrefix:schedulePrefix];
	[self addSetOptionalPropertyRule:@"previousTripId" forPrefix:[self extendPrefix:schedulePrefix withValue:@"previousTripId"]];
	[self addSetOptionalPropertyRule:@"nextTripId" forPrefix:[self extendPrefix:schedulePrefix withValue:@"nextTripId"]];
	[self addSetNext:@selector(setSchedule:) forPrefix:schedulePrefix];
	[self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:schedulePrefix];
	
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
	
	[self addTarget:self selector:@selector(setReferencesForContext:name:value:) forRuleTarget:OBAJsonDigesterRuleTargetEnd prefix:prefix];
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

- (void) setReferencesForContext:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	OBAHasReferencesV2 * top = [context peek:0];
	OBAReferencesV2 * refs = [context getParameterForKey:kReferences];
	top.references = refs;
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

@end 


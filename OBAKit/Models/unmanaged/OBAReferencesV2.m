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

#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBAAgencyV2.h>
#import <OBAKit/OBARouteV2.h>
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBATripV2.h>
#import <OBAKit/OBASituationV2.h>

@implementation OBAReferencesV2 {
    NSMutableDictionary * _agencies;
    NSMutableDictionary * _routes;
    NSMutableDictionary * _stops;
    NSMutableDictionary * _trips;
    NSMutableDictionary * _situations;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _agencies = [[NSMutableDictionary alloc] init];
        _routes = [[NSMutableDictionary alloc] init];
        _stops = [[NSMutableDictionary alloc] init];
        _trips = [[NSMutableDictionary alloc] init];
        _situations = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addAgency:(OBAAgencyV2*)agency {
    _agencies[agency.agencyId] = agency;
}

- (OBAAgencyV2*)getAgencyForId:(NSString*)agencyId {
    return _agencies[agencyId];
}

- (NSDictionary*)agencies {
    return [NSDictionary dictionaryWithDictionary:_agencies];
}

- (void)addRoute:(OBARouteV2*)route {
    _routes[route.routeId] = route;
}

- (OBARouteV2*)getRouteForId:(NSString*)routeId {
    return _routes[routeId];
}    

- (void)addStop:(OBAStopV2*)stop {
    _stops[stop.stopId] = stop;
}

- (OBAStopV2*) getStopForId:(NSString*)stopId {
    return _stops[stopId];
}

- (void) addTrip:(OBATripV2*)trip {
    _trips[trip.tripId] = trip;
}

- (OBATripV2*) getTripForId:(NSString*)tripId {
    return _trips[tripId];
}

- (void) addSituation:(OBASituationV2*)situation {
    _situations[situation.situationId] = situation;
}

- (OBASituationV2*) getSituationForId:(NSString*)situationId {
    return _situations[situationId];
}

- (void) clear {
    [_agencies removeAllObjects];
    [_routes removeAllObjects];
    [_stops removeAllObjects];
    [_trips removeAllObjects];
    [_situations removeAllObjects];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%@ agencies:%lu routes:%lu stops:%lu trips:%lu situations:%lu",
            [super description],
            (unsigned long)[_agencies count],
            (unsigned long)[_routes count],
            (unsigned long)[_stops count],
            (unsigned long)[_trips count],
            (unsigned long)[_situations count]];
}

@end

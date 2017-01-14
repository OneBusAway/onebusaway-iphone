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

#import <OBAKit/OBABookmarkV2.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBAArrivalsAndDeparturesForStopV2.h>
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBARegionV2.h>
#import <OBAKit/NSObject+OBADescription.h>
#import <OBAKit/NSCoder+OBAAdditions.h>

@implementation OBABookmarkV2

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture region:(OBARegionV2*)region {
    self = [self init];

    if (self) {
        OBAStopV2 *stop = arrivalAndDeparture.stop;
        _routeShortName = [arrivalAndDeparture.routeShortName copy];
        _routeID = [arrivalAndDeparture.routeId copy];
        _tripHeadsign = [arrivalAndDeparture.tripHeadsign copy];
        _name = [stop.nameWithDirection copy];
        _stopId = [stop.stopId copy];
        _regionIdentifier = region.identifier;
        _stop = [stop copy];
        _bookmarkVersion = OBABookmarkVersion260;
    }
    return self;
}

- (instancetype)initWithStop:(OBAStopV2*)stop region:(OBARegionV2*)region {
    self = [super init];

    if (self) {
        _name = [stop.nameWithDirection copy];
        _stopId = [stop.stopId copy];
        _regionIdentifier = region.identifier;
        _stop = [stop copy];
        _bookmarkVersion = OBABookmarkVersion252;
    }

    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder*)coder {
    if (self = [super init]) {
        _name = [coder oba_decodeObject:@selector(name)];

        // Handle legacy bookmark models.
        NSArray *stopIds = [coder decodeObjectForKey:@"stopIds"];
        if (stopIds && stopIds.count > 0) {
            _stopId = stopIds[0];
        }
        else {
            _stopId = [coder oba_decodeObject:@selector(stopId)];
        }

        // Normally, we'd simply try decoding the object and use the fact that
        // nil would simply resolve to 0 to our advantage, but the Tampa region
        // has the ID of 0, so we're stuck trying to be clever here to work
        // around that issue.
        if ([coder oba_containsValue:@selector(regionIdentifier)]) {
            _regionIdentifier = [coder oba_decodeInteger:@selector(regionIdentifier)];
        }
        else {
            _regionIdentifier = NSNotFound;
        }

        _stop = [coder oba_decodeObject:@selector(stop)];

        // New in 2.6.0
        _routeShortName = [coder oba_decodeObject:@selector(routeShortName)];
        _tripHeadsign = [coder oba_decodeObject:@selector(tripHeadsign)];
        _routeID = [coder oba_decodeObject:@selector(routeID)];
        _sortOrder = [coder oba_decodeInteger:@selector(sortOrder)];
        _bookmarkVersion = [coder oba_decodeInteger:@selector(bookmarkVersion)];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder oba_encodeObject:_name forSelector:@selector(name)];
    [coder oba_encodeObject:_stopId forSelector:@selector(stopId)];
    [coder oba_encodeObject:_stop forSelector:@selector(stop)];
    [coder oba_encodeInteger:_regionIdentifier forSelector:@selector(regionIdentifier)];

    // New in 2.6.0
    [coder oba_encodeObject:_routeShortName forSelector:@selector(routeShortName)];
    [coder oba_encodeObject:_tripHeadsign forSelector:@selector(tripHeadsign)];
    [coder oba_encodeObject:_routeID forSelector:@selector(routeID)];
    [coder oba_encodeInteger:_sortOrder forSelector:@selector(sortOrder)];
    [coder oba_encodeInteger:_bookmarkVersion forSelector:@selector(bookmarkVersion)];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone*)zone {
    OBABookmarkV2 *bookmark = [[self.class alloc] init];
    bookmark->_name = [_name copyWithZone:zone];
    bookmark->_routeShortName = [_routeShortName copyWithZone:zone];
    bookmark->_stopId = [_stopId copyWithZone:zone];
    bookmark->_tripHeadsign = [_tripHeadsign copyWithZone:zone];
    bookmark->_routeID = [_routeID copyWithZone:zone];
    bookmark->_stop = [_stop copyWithZone:zone];
    bookmark->_group = _group;
    bookmark->_regionIdentifier = _regionIdentifier;
    bookmark->_sortOrder = _sortOrder;
    bookmark->_bookmarkVersion = _bookmarkVersion;

    return bookmark;
}

#pragma mark - MKAnnotation

- (NSString*)title {
    return self.name;
}

- (NSString*)subtitle {
    if (self.stop) {
        return self.stop.routeNamesAsString;
    }
    else {
        return nil;
    }
}

- (CLLocationCoordinate2D)coordinate {
    return self.stop.coordinate;
}

#pragma mark - Misc

- (BOOL)isValidModel {
    // TODO: this should really be smarter and check for a variety of
    // properties depending on whether it is a 252 or 260-style bookmark.
    // However, for the purposes of fixing https://github.com/OneBusAway/onebusaway-iphone/issues/711,
    // the check for the name is sufficient.
    return self.name.length > 0;
}

- (NSArray<OBAArrivalAndDepartureV2*>*)matchingArrivalsAndDeparturesForStop:(OBAArrivalsAndDeparturesForStopV2*)dep {
    NSMutableArray *matches = [NSMutableArray array];

    for (OBAArrivalAndDepartureV2 *ad in dep.arrivalsAndDepartures) {
        if ([self matchesArrivalAndDeparture:ad]) {
            [matches addObject:ad];
        }
    }

    return [NSArray arrayWithArray:matches];
}

// Belt and suspenders, but necessary?
- (NSString*)stopId {
    if (!_stopId && _stop) {
        _stopId = _stop.stopId;
    }
    return _stopId;
}

- (OBARouteType)routeType {
    return self.stop.firstAvailableRouteTypeForStop;
}

- (BOOL)matchesArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    if (![self.stop isEqual:arrivalAndDeparture.stop]) {
        return NO;
    }

    if (![self.routeID isEqual:arrivalAndDeparture.routeId]) {
        return NO;
    }

    // because of the trip headsign munging that sometimes takes place elsewhere in the codebase,
    // we need to do a case insensitive comparison to ensure that these headsigns match. Ideally,
    // we wouldn't have to do such a fragile comparison in the first place...
    if ([self.tripHeadsign compare:arrivalAndDeparture.tripHeadsign options:NSCaseInsensitiveSearch] != NSOrderedSame) {
        return NO;
    }

    return YES;
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }

    if (self.regionIdentifier != [object regionIdentifier]) {
        return NO;
    }

    if (![self.stopId isEqual:[object stopId]]) {
        return NO;
    }

    if (![self.routeShortName isEqual:[object routeShortName]]) {
        return NO;
    }

    if (![self.tripHeadsign isEqual:[object tripHeadsign]]) {
        return NO;
    }

    if (![self.routeID isEqual:[object routeID]]) {
        return NO;
    }

    if (self.bookmarkVersion != [object bookmarkVersion]) {
        return NO;
    }

    return YES;
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%@_%@_%@_%@_%@_%@", NSStringFromClass(self.class), @(self.regionIdentifier), self.stopId, self.routeShortName, self.tripHeadsign, self.routeID] hash];
}

#pragma mark - NSObject

- (NSString*)description {
    return [self oba_description:@[@"name", @"routeShortName", @"stopId", @"stop", @"regionIdentifier", @"routeType", @"routeID", @"tripHeadsign"] keyPaths:@[@"group.name"]];
}


@end

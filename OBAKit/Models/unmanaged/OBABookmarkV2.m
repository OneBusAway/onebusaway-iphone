#import "OBABookmarkV2.h"
#import "OBAArrivalAndDepartureV2.h"
#import "OBAArrivalsAndDeparturesForStopV2.h"
#import "OBAStopV2.h"
#import "OBARegionV2.h"
#import "NSObject+OBADescription.h"

static NSString * const kRegionIdentifier = @"regionIdentifier";
static NSString * const kName = @"name";
static NSString * const kRouteShortName = @"routeShortName";
static NSString * const kStopId = @"stopId";
static NSString * const kStop = @"stop";
static NSString * const kRouteID = @"routeID";
static NSString * const kTripHeadsign = @"tripHeadsign";
static NSString * const kSortOrder = @"sortOrder";
static NSString * const kBookmarkVersion = @"bookmarkVersion";

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
        _name = [coder decodeObjectForKey:kName];

        // Handle legacy bookmark models.
        NSArray *stopIds = [coder decodeObjectForKey:@"stopIds"];
        if (stopIds && stopIds.count > 0) {
            _stopId = stopIds[0];
        }
        else {
            _stopId = [coder decodeObjectForKey:kStopId];
        }

        // Normally, we'd simply try decoding the object and use the fact that
        // nil would simply resolve to 0 to our advantage, but the Tampa region
        // has the ID of 0, so we're stuck trying to be clever here to work
        // around that issue.
        if ([coder containsValueForKey:kRegionIdentifier]) {
            _regionIdentifier = [coder decodeIntegerForKey:kRegionIdentifier];
        }
        else {
            _regionIdentifier = NSNotFound;
        }

        _stop = [coder decodeObjectForKey:kStop];

        // New in 2.6.0
        _routeShortName = [coder decodeObjectForKey:kRouteShortName];
        _tripHeadsign = [coder decodeObjectForKey:kTripHeadsign];
        _routeID = [coder decodeObjectForKey:kRouteID];
        _sortOrder = [coder decodeIntegerForKey:kSortOrder];
        _bookmarkVersion = [coder decodeIntegerForKey:kBookmarkVersion];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:_name forKey:kName];
    [coder encodeObject:_stopId forKey:kStopId];
    [coder encodeObject:_stop forKey:kStop];
    [coder encodeInteger:_regionIdentifier forKey:kRegionIdentifier];

    // New in 2.6.0
    [coder encodeObject:_routeShortName forKey:kRouteShortName];
    [coder encodeObject:_tripHeadsign forKey:kTripHeadsign];
    [coder encodeObject:_routeID forKey:kRouteID];
    [coder encodeInteger:_sortOrder forKey:kSortOrder];
    [coder encodeInteger:_bookmarkVersion forKey:kBookmarkVersion];
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

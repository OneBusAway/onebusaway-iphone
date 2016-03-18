#import "OBABookmarkV2.h"
#import "OBAStopV2.h"
#import "OBARegionV2.h"

static NSString * const kRegionIdentifier = @"regionIdentifier";
static NSString * const kName = @"name";
static NSString * const kStopId = @"stopId";
static NSString * const kStop = @"stop";

@implementation OBABookmarkV2

- (instancetype)initWithStop:(OBAStopV2*)stop region:(OBARegionV2*)region {
    self = [self init];

    if (self) {
        _name = stop.direction ? [NSString stringWithFormat:@"%@ [%@]",stop.name,stop.direction] : [stop.name copy];
        _stopId = [stop.stopId copy];
        //    bookmark.routeID = TODO - SOME WAY TO GET A ROUTE ID
        //    bookmark.headsign = stop.
        _regionIdentifier = region.identifier;
        _stop = [stop copy];
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
        else if ([coder containsValueForKey:@"stopID"]) {
            // TODO: remove this block of code once 2.5.1 ships.
            // It's the result of a dumb bug I introduced in one
            // beta version of 2.5.0.
            _stopId = [coder decodeObjectForKey:@"stopID"];
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
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:_name forKey:kName];
    [coder encodeObject:_stopId forKey:kStopId];
    [coder encodeObject:_stop forKey:kStop];
    [coder encodeInteger:_regionIdentifier forKey:kRegionIdentifier];
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

#pragma mark - NSObject

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p> :: {name: %@, group: %@, stopID: %@, regionIdentifier: %@}", self.class, self, self.name, self.group, self.stopId, @(self.regionIdentifier)];
}

@end

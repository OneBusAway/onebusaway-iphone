#import "OBABookmarkV2.h"
#import "OBAStopV2.h"
#import "OBARegionV2.h"

static NSString * const kRegionIdentifier = @"regionIdentifier";
static NSString * const kName = @"name";
static NSString * const kStopID = @"stopID";
static NSString * const kLatitude = @"latitude";
static NSString * const kLongitude = @"longitude";

@implementation OBABookmarkV2

- (instancetype)initWithStop:(OBAStopV2*)stop region:(OBARegionV2*)region {
    self = [self init];

    if (self) {
        _name = stop.direction ? [NSString stringWithFormat:@"%@ [%@]",stop.name,stop.direction] : [stop.name copy];
        _stopID = [stop.stopId copy];
        _coordinate = stop.coordinate;
        //    bookmark.routeID = TODO - SOME WAY TO GET A ROUTE ID
        //    bookmark.headsign = stop.
        _regionIdentifier = region.identifier;
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
            _stopID = stopIds[0];
        }
        else {
            _stopID = [coder decodeObjectForKey:kStopID];
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

        _coordinate = kCLLocationCoordinate2DInvalid;
        if ([coder containsValueForKey:kLatitude] && [coder containsValueForKey:kLongitude]) {
            _coordinate = CLLocationCoordinate2DMake([coder decodeDoubleForKey:kLatitude], [coder decodeDoubleForKey:kLongitude]);
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:_name forKey:kName];
    [coder encodeObject:_stopID forKey:kStopID];
    [coder encodeInteger:_regionIdentifier forKey:kRegionIdentifier];
    [coder encodeDouble:_coordinate.latitude forKey:kLatitude];
    [coder encodeDouble:_coordinate.longitude forKey:kLongitude];
}

#pragma mark - MKAnnotation

- (NSString*)title {
    return self.name;
}

- (NSString*)subtitle {
    return @"TBD!";
}

#pragma mark - NSObject

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p> :: {name: %@, group: %@, stopID: %@, regionIdentifier: %@}", self.class, self, self.name, self.group, self.stopID, @(self.regionIdentifier)];
}

@end

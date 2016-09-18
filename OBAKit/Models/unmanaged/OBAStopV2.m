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

#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBARouteV2.h>

@interface OBAStopV2 ()
@property(nonatomic,strong,readwrite) NSArray<OBARouteV2*> *routes;
@end

@implementation OBAStopV2

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        _stopId = [aDecoder decodeObjectForKey:@"stopId"];
        _name = [aDecoder decodeObjectForKey:@"name"];
        _code = [aDecoder decodeObjectForKey:@"code"];
        _direction = [aDecoder decodeObjectForKey:@"direction"];

        if ([aDecoder containsValueForKey:@"lat"]) {
            _lat = [aDecoder decodeDoubleForKey:@"lat"];
        }
        else {
            _lat = [[aDecoder decodeObjectForKey:@"latitude"] doubleValue];
        }

        if ([aDecoder containsValueForKey:@"lon"]) {
            _lon = [aDecoder decodeDoubleForKey:@"lon"];
        }
        else {
            _lon = [[aDecoder decodeObjectForKey:@"longitude"] doubleValue];
        }

        _routeIds = [aDecoder decodeObjectForKey:@"routeIds"];
        _routes = [aDecoder decodeObjectForKey:@"routes"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_stopId forKey:@"stopId"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_code forKey:@"code"];
    [aCoder encodeObject:_direction forKey:@"direction"];
    [aCoder encodeDouble:_lat forKey:@"lat"];
    [aCoder encodeDouble:_lon forKey:@"lon"];
    [aCoder encodeObject:_routeIds forKey:@"routeIds"];
    [aCoder encodeObject:_routes forKey:@"routes"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    OBAStopV2 *stop = [[self.class allocWithZone:zone] init];
    stop->_stopId = [_stopId copyWithZone:zone];
    stop->_name = [_name copyWithZone:zone];
    stop->_code = [_code copyWithZone:zone];
    stop->_direction = [_direction copyWithZone:zone];
    stop->_lat = _lat;
    stop->_lon = _lon;
    stop->_routeIds = [_routeIds copyWithZone:zone];
    stop->_routes = [_routes copyWithZone:zone];

    return stop;
}

#pragma mark - Public

- (NSArray<OBARouteV2*>*)routes {

    @synchronized (self) {
        if (!_routes) {
            NSMutableArray *routes = [NSMutableArray array];

            for (NSString *routeId in _routeIds) {
                OBARouteV2 *route = [self.references getRouteForId:routeId];
                [routes addObject:route];
            }

            [routes sortUsingSelector:@selector(compareUsingName:)];

            _routes = [[NSArray alloc] initWithArray:routes copyItems:YES];
        }
    }

    return _routes;
}

- (NSComparisonResult) compareUsingName:(OBAStopV2*)aStop {
    return [self.name compare:aStop.name options:NSNumericSearch];
}

- (NSString*) routeNamesAsString {
    NSMutableArray *safeShortNames = [NSMutableArray array];
    
    for (OBARouteV2 *route in self.routes) {
        [safeShortNames addObject:route.safeShortName];
    }
    
    return [safeShortNames componentsJoinedByString:@", "];
}

#pragma mark - Public Helpers

- (OBARouteType)firstAvailableRouteTypeForStop {
    for (OBARouteV2 *route in self.routes) {
        if (route.routeType) {
            return route.routeType.integerValue;
        }
    }

    return OBARouteTypeUnknown;
}

- (NSString*)nameWithDirection {
    if (self.direction) {
        return [NSString stringWithFormat:@"%@ [%@]", self.name, self.direction];
    }
    else {
        return [self.name copy];
    }
}

#pragma mark - MKAnnotation

- (NSString*) title {
    return self.name;
}

- (NSString*) subtitle {
    NSString * r = [self routeNamesAsString];

    if (self.direction) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ bound - Routes: %@", @""), self.direction, r];
    }
    else {
        return [NSString stringWithFormat:NSLocalizedString(@"Routes: %@", @""), r];
    }
}

- (CLLocationCoordinate2D) coordinate {
    CLLocationCoordinate2D c = {self.lat,self.lon};
    return c;
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[OBAStopV2 class]]) {
        return NO;
    }

    return [self.stopId isEqual:[object stopId]];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ %p> {id: %@, name: %@, code: %@, direction: %@, lat/lng: (%@, %@), routeIDs: %@}", NSStringFromClass(self.class), self, self.stopId, self.name, self.code, self.direction, @(self.lat), @(self.lon), self.routeIds];
}

@end

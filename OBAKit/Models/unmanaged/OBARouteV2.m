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

#import <OBAKit/OBARouteV2.h>
#import <OBAKit/NSObject+OBADescription.h>

@interface OBARouteV2 ()
@property(nonatomic,copy,readwrite) OBAAgencyV2 *agency;
@end

@implementation OBARouteV2

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        _routeId = [aDecoder decodeObjectForKey:@"routeId"];
        _shortName = [aDecoder decodeObjectForKey:@"shortName"];
        _longName = [aDecoder decodeObjectForKey:@"longName"];
        _routeType = [aDecoder decodeObjectForKey:@"routeType"];
        _agencyId = [aDecoder decodeObjectForKey:@"agencyId"];
        _agency = [aDecoder decodeObjectForKey:@"agency"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_routeId forKey:@"routeId"];
    [aCoder encodeObject:_shortName forKey:@"shortName"];
    [aCoder encodeObject:_longName forKey:@"longName"];
    [aCoder encodeObject:_routeType forKey:@"routeType"];
    [aCoder encodeObject:_agencyId forKey:@"agencyId"];
    [aCoder encodeObject:_agency forKey:@"agency"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    OBARouteV2 *route = [[self.class alloc] init];
    route->_routeId = [_routeId copyWithZone:zone];
    route->_shortName = [_shortName copyWithZone:zone];
    route->_longName = [_longName copyWithZone:zone];
    route->_routeType = [_routeType copyWithZone:zone];
    route->_agencyId = [_agencyId copyWithZone:zone];
    route->_agency = [_agency copyWithZone:zone];

    return route;
}

#pragma mark - Public

- (OBAAgencyV2*) agency {
    if (!_agency) {
        _agency = [[self.references getAgencyForId:_agencyId] copy];
    }
    return _agency;
}

- (NSString *)safeShortName {
    return [(self.shortName ?: self.longName) copy];
}

- (NSComparisonResult) compareUsingName:(OBARouteV2*)aRoute {
    NSString * name1 = [self safeShortName];
    NSString * name2 = [aRoute safeShortName];
    return [name1 compare:name2 options:NSNumericSearch];
}

- (NSString*)fullRouteName {
    NSMutableArray *pieces = [NSMutableArray array];

    if (self.shortName) {
        [pieces addObject:self.shortName];
    }
    if (self.longName) {
        [pieces addObject:self.longName];
    }
    return [pieces componentsJoinedByString:@" - "];
}

#pragma mark - NSObject

- (NSString*)description {
    return [self oba_description:@[@"routeId", @"shortName", @"longName", @"routeType", @"agencyId", @"agency", @"safeShortName"]];
}

@end

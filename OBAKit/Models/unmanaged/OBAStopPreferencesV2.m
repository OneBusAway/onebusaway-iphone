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

#import <OBAKit/OBAStopPreferencesV2.h>
#import <OBAKit/NSObject+OBADescription.h>
#import <OBAKit/NSCoder+OBAAdditions.h>

NSString * _Nullable NSStringFromOBASortTripsByTypeV2(OBASortTripsByTypeV2 val);
NSString * _Nullable NSStringFromOBASortTripsByTypeV2(OBASortTripsByTypeV2 val) {
    switch (val) {
        case OBASortTripsByDepartureTimeV2:
            return @"OBASortTripsByDepartureTimeV2";
        case OBASortTripsByRouteNameV2:
            return @"OBASortTripsByRouteNameV2";
        default:
            return nil;
    }
}

@implementation OBAStopPreferencesV2
@dynamic hasFilteredRoutes;

- (instancetype)init {
    self = [super init];
    if (self) {
        _sortTripsByType = OBASortTripsByDepartureTimeV2;
        _routeFilter = [[NSMutableSet alloc] init];
    }
    return self;
}

- (instancetype)initWithStopPreferences:(OBAStopPreferencesV2*)preferences {
    self = [super init];
    if( self ) {
        _sortTripsByType = preferences.sortTripsByType;
        _routeFilter = [[NSMutableSet alloc] initWithSet:preferences.routeFilter];
    }
    return self;    
}

#pragma mark - NSCoder

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super init];
    if (self) {
        _sortTripsByType = [coder oba_decodeInteger:@selector(sortTripsByType)];
        _routeFilter = [coder oba_decodeObject:@selector(routeFilter)];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder oba_encodeInteger:_sortTripsByType forSelector:@selector(sortTripsByType)];
    [coder oba_encodePropertyOnObject:self withSelector:@selector(routeFilter)];
}


#pragma mark - Public Methods

- (void)toggleTripSorting {
    if (self.sortTripsByType == OBASortTripsByDepartureTimeV2) {
        self.sortTripsByType = OBASortTripsByRouteNameV2;
    }
    else {
        self.sortTripsByType = OBASortTripsByDepartureTimeV2;
    }
}

- (BOOL)isRouteIDDisabled:(NSString*)routeID {
    return [_routeFilter containsObject:routeID];
}

- (BOOL)isRouteIdEnabled:(NSString*)routeId {
    return ![self isRouteIDDisabled:routeId];
}
        
- (void)setEnabled:(BOOL)isEnabled forRouteId:(NSString*)routeId {
    if (isEnabled) {
        [_routeFilter removeObject:routeId];
    }
    else {
        [_routeFilter addObject:routeId];
    }
}

- (BOOL)toggleRouteID:(NSString*)routeID {
    if ([_routeFilter containsObject:routeID]) {
        [_routeFilter removeObject:routeID];
    }
    else {
        [_routeFilter addObject:routeID];
    }

    return ![_routeFilter containsObject:routeID];
}

- (BOOL)hasFilteredRoutes {
    return self.routeFilter.count > 0;
}

- (NSString*)formattedSortTripsByType {
    return NSStringFromOBASortTripsByTypeV2(self.sortTripsByType);
}

#pragma mark - NSObject

- (NSString*)description {
    return [self oba_description:@[@"formattedSortTripsByType", @"routeFilter", @"hasFilteredRoutes"]];
}

@end

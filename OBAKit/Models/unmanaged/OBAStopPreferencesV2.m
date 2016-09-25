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

@implementation OBAStopPreferencesV2
@dynamic hasFilteredRoutes;

- (instancetype)init {
    self = [super init];
    if (self) {
        _routeFilter = [[NSMutableSet alloc] init];
    }
    return self;
}

- (instancetype)initWithStopPreferences:(OBAStopPreferencesV2*)preferences {
    self = [super init];
    if( self ) {
        _routeFilter = [[NSMutableSet alloc] initWithSet:preferences.routeFilter];
    }
    return self;    
}

#pragma mark - NSCoder

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super init];
    if( self ) {
        _routeFilter = [coder decodeObjectForKey:@"routeFilter"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:_routeFilter forKey:@"routeFilter"];
}

#pragma mark - Public Methods

- (BOOL)isRouteIDDisabled:(NSString*)routeID {
    return [_routeFilter containsObject:routeID];
}

- (BOOL)isRouteIdEnabled:(NSString*)routeId {
    return ![_routeFilter containsObject:routeId];
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

#pragma mark - NSObject

- (NSString*)description {
    return [self oba_description:@[@"routeFilter", @"hasFilteredRoutes"]];
}

@end

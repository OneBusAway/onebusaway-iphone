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

#import <OBAKit/OBAStopsForRouteV2.h>
#import <OBAKit/OBAStopV2.h>

@implementation OBAStopsForRouteV2

- (id) initWithReferences:(OBAReferencesV2*)refs {
    self = [super initWithReferences:refs];
    if (self) {
        _stopIds = [[NSMutableArray alloc] init];
        _polylines = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void) addStopId:(NSString*)stopId {
    [_stopIds addObject:stopId];
}

- (void) addPolyline:(NSString*)polyline {
    [_polylines addObject:polyline];
}

- (OBARouteV2*) route {
    return [self.references getRouteForId:_routeId];
}

- (NSArray*) stops {
    NSMutableArray * stops = [[NSMutableArray alloc] init];
    OBAReferencesV2 * refs = [self references];
    for( NSString * stopId in _stopIds ) {
        OBAStopV2 * stop = [refs getStopForId:stopId];
        if( stop )
            [stops addObject:stop];
    }
    return stops;
}

- (NSArray*) polylines {
    return _polylines;
}
    
@end

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

#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBARouteV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAStopsForRouteV2 : OBAHasReferencesV2 {
    NSString * _routeId;
    NSMutableArray * _stopIds;
    NSMutableArray * _polylines;
}

@property (nonatomic, strong) NSString * routeId;
@property (weak, nonatomic, readonly) OBARouteV2 * route;
@property (weak, nonatomic, readonly) NSArray * stops;
@property (weak, nonatomic, readonly) NSArray * polylines;

- (id) initWithReferences:(OBAReferencesV2*)refs;

- (void) addStopId:(NSString*)stopId;
- (void) addPolyline:(NSString*)polyline;

@end

NS_ASSUME_NONNULL_END

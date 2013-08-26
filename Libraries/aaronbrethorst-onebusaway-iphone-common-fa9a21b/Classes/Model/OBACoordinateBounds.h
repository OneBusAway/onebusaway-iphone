/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>


@interface OBACoordinateBounds : NSObject <NSCoding>

- (id) initWithBounds:(OBACoordinateBounds*)bounds;
- (id) initWithRegion:(MKCoordinateRegion)region;
+ (id) bounds;

@property (nonatomic,readonly) BOOL empty;
@property (nonatomic) double minLatitude;
@property (nonatomic) double maxLatitude;
@property (nonatomic) double minLongitude;
@property (nonatomic) double maxLongitude;
@property (nonatomic,readonly) MKCoordinateRegion region;
@property (nonatomic,readonly) CLLocationCoordinate2D center;
@property (nonatomic,readonly) MKCoordinateSpan span;

- (void) addLat:(double)lat lon:(double)lon;
- (void) addCoordinate:(CLLocationCoordinate2D)coordinate;
- (void) addLocation:(CLLocation*)location;
- (void) addLocations:(NSArray*)locations;
- (void) addRegion:(MKCoordinateRegion)region;

- (void) expandByRatio:(double)ratio;

@end

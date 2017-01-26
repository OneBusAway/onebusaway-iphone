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

#import <OBAKit/OBACoordinateBounds.h>
#import <OBAKit/NSCoder+OBAAdditions.h>

@implementation OBACoordinateBounds

- (instancetype)init {
    self = [super init];
    if (self) {
        _empty = YES;
    }
    return self;
}

- (id) initWithBounds:(OBACoordinateBounds*)bounds {
    self = [super init];
    if (self) {
        _empty = bounds.empty;
        _minLatitude = bounds.minLatitude;
        _maxLatitude = bounds.maxLatitude;
        _minLongitude = bounds.minLongitude;
        _maxLongitude = bounds.maxLongitude;
    }
    return self;
}

- (instancetype)initWithRegion:(MKCoordinateRegion)region {
    self = [super init];
    if (self) {
        _empty = YES;
        [self addRegion:region];
    }
    return self;
}

#pragma mark - NSCoder

- (id)initWithCoder:(NSCoder*)coder {
    self = [super init];
    if (self) {
        _empty = [coder oba_decodeBool:@selector(empty)];
        _minLatitude = [coder oba_decodeDouble:@selector(minLatitude)];
        _maxLatitude = [coder oba_decodeDouble:@selector(maxLatitude)];
        _minLongitude = [coder oba_decodeDouble:@selector(minLongitude)];
        _maxLongitude = [coder oba_decodeDouble:@selector(maxLongitude)];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder oba_encodeBool:_empty forSelector:@selector(empty)];
    [coder oba_encodeDouble:_minLatitude forSelector:@selector(minLatitude)];
    [coder oba_encodeDouble:_maxLatitude forSelector:@selector(maxLatitude)];
    [coder oba_encodeDouble:_minLongitude forSelector:@selector(minLongitude)];
    [coder oba_encodeDouble:_maxLongitude forSelector:@selector(maxLongitude)];
}

#pragma mark - Public Methods

- (MKCoordinateRegion)region {
    return MKCoordinateRegionMake(self.center,self.span);
}

- (CLLocationCoordinate2D) center {
    CLLocationCoordinate2D center = {0.0,0.0};
    if( ! _empty ) {
        center.latitude = (_minLatitude + _maxLatitude)/2;
        center.longitude = (_minLongitude + _maxLongitude)/2;
    }
    return center;
}

- (MKCoordinateSpan) span {
    MKCoordinateSpan span = MKCoordinateSpanMake(0.0,0.0);
    if( ! _empty ) {
        span.latitudeDelta = _maxLatitude - _minLatitude;
        span.longitudeDelta = _maxLongitude - _minLongitude;
    }
    return span;
}

- (void) addRegion:(MKCoordinateRegion)region {
    CLLocationCoordinate2D c = region.center;
    MKCoordinateSpan span = region.span;
    [self addLat:c.latitude-span.latitudeDelta/2 lon:c.longitude-span.longitudeDelta/2];
    [self addLat:c.latitude+span.latitudeDelta/2 lon:c.longitude+span.longitudeDelta/2];
}

- (void) addLocations:(NSArray*)locations {
    for( CLLocation * location in locations)
        [self addLocation:location];
}

- (void) addLocation:(CLLocation*)location {
    [self addCoordinate:location.coordinate];
}

- (void) addCoordinate:(CLLocationCoordinate2D)coordinate {
    [self addLat:coordinate.latitude lon:coordinate.longitude];
}

- (void) addLat:(double)lat lon:(double)lon {
    if( _empty ) {
        _empty = NO;

        _minLatitude = lat;
        _maxLatitude = lat;
        _minLongitude = lon;
        _maxLongitude = lon;
    }
    else {
        _minLatitude = MIN(_minLatitude,lat);
        _maxLatitude = MAX(_maxLatitude,lat);
        _minLongitude = MIN(_minLongitude,lon);
        _maxLongitude = MAX(_maxLongitude,lon);
    }
}

- (void)expandByRatio:(double)ratio {
    if (self.empty) {
        return;
    }
    double latDelta = (_maxLatitude - _minLatitude) * ratio / 2;
    double lonDelta = (_maxLongitude - _minLongitude) * ratio / 2;
    _maxLatitude += latDelta;
    _minLatitude -= latDelta;
    _maxLongitude += lonDelta;
    _minLongitude -= lonDelta;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%f %f %f %f",_minLatitude,_minLongitude,_maxLatitude,_maxLongitude];
}

@end

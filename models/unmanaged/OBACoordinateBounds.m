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

#import "OBACoordinateBounds.h"


@implementation OBACoordinateBounds

- (id) init {
    self = [super init];
    if( self ) {
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

- (id) initWithRegion:(MKCoordinateRegion)region {
    self = [super init];
    if( self ) {
        _empty = YES;
        [self addRegion:region];
    }
    return self;
}

- (id) initWithCoder:(NSCoder*)coder {
    self = [super init];
    if( self ) {
        _empty = [coder decodeBoolForKey:@"empty"];
        _minLatitude = [coder decodeDoubleForKey:@"minLatitude"];
        _maxLatitude = [coder decodeDoubleForKey:@"maxLatitude"];
        _minLongitude = [coder decodeDoubleForKey:@"minLongitude"];
        _maxLongitude = [coder decodeDoubleForKey:@"maxLongitude"];
    }
    return self;
}

+ (id) bounds {
    return [[OBACoordinateBounds alloc] init];
}

- (MKCoordinateRegion) region {
    return MKCoordinateRegionMake([self center],[self span]);
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

- (void) expandByRatio:(double)ratio {
    if( _empty )
        return;
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

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
    [coder encodeBool:_empty forKey:@"empty"];
    [coder encodeDouble:_minLatitude forKey:@"minLatitude"];
    [coder encodeDouble:_maxLatitude forKey:@"maxLatitude"];
    [coder encodeDouble:_minLongitude forKey:@"minLongitude"];
    [coder encodeDouble:_maxLongitude forKey:@"maxLongitude"];
}

@end

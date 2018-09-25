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

#import <OBAKit/OBAStopAccessEventV2.h>
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/NSCoder+OBAAdditions.h>

#import <MapKit/MapKit.h>

@implementation OBAStopAccessEventV2

- (instancetype)initWithStop:(OBAStopV2*)stop {
    self = [super init];

    if (self) {
        [self commonInit];

        _title = [stop.title copy];
        _subtitle = [stop.subtitle copy];
        _stopID = [stop.stopId copy];
        _coordinate = stop.coordinate;
    }

    return self;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _coordinate = kCLLocationCoordinate2DInvalid;
}

#pragma mark - NSCoder Methods

- (id)initWithCoder:(NSCoder*)coder {
    self = [super init];
    if (self) {
        [self commonInit];

        _title = [coder oba_decodeObject:@selector(title)];
        _subtitle = [coder oba_decodeObject:@selector(subtitle)];

        //
        // TODO: eliminate this compatibility code in, say, 2020.
        //
        // Up until 18.2.0, it was possible to encode multiple stop IDs
        // within a single stop access event object. However, this functionality
        // was limited to a single stop ID. As a result, we need to account
        // for this for the foreseeable future.
        NSArray *stopIds = [coder decodeObjectForKey:@"stopIds"];
        if (stopIds.count > 0) {
            _stopID = [stopIds firstObject];
        }
        else {
            _stopID = [coder oba_decodeObject:@selector(stopID)];
        }

        if ([coder containsValueForKey:@"latitude"] && [coder containsValueForKey:@"longitude"]) {
            _coordinate = CLLocationCoordinate2DMake([coder decodeDoubleForKey:@"latitude"], [coder decodeDoubleForKey:@"longitude"]);
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder oba_encodePropertyOnObject:self withSelector:@selector(title)];
    [coder oba_encodePropertyOnObject:self withSelector:@selector(subtitle)];
    [coder oba_encodePropertyOnObject:self withSelector:@selector(stopID)];

    if (self.hasLocation) {
        [coder encodeDouble:_coordinate.latitude forKey:@"latitude"];
        [coder encodeDouble:_coordinate.longitude forKey:@"longitude"];
    }
}

#pragma mark - Location

- (BOOL)hasLocation {
    return CLLocationCoordinate2DIsValid(self.coordinate);
}

#pragma mark - Equality

- (BOOL)isEqual:(OBAStopAccessEventV2*)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:self.class]) {
        return NO;
    }

    return [self.title isEqual:object.title]
        && [self.subtitle isEqual:object.subtitle]
        && [self.stopID isEqual:object.stopID]
        && self.coordinate.latitude == object.coordinate.latitude
        && self.coordinate.longitude == object.coordinate.longitude;
}

- (NSUInteger)hash {
    return [NSString stringWithFormat:@"%@_%@_%@_%@_%@", self.title, self.subtitle, self.stopID, @(self.coordinate.latitude), @(self.coordinate.longitude)].hash;
}

@end

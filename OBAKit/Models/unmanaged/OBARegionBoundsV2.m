//
//  OBARegionBoundsV2.m
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//

#import <OBAKit/OBARegionBoundsV2.h>
#import <OBAKit/NSObject+OBADescription.h>
#import <OBAKit/NSCoder+OBAAdditions.h>

@implementation OBARegionBoundsV2

- (instancetype)initWithLat:(double)lat latSpan:(double)latSpan lon:(double)lon lonSpan:(double)lonSpan {
    self = [super init];

    if (self) {
        _lat = lat;
        _latSpan = latSpan;
        _lon = lon;
        _lonSpan = lonSpan;
    }
    return self;
}

#pragma mark - NSCoder

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];

    if (self) {
        _lat = [decoder oba_decodeDouble:@selector(lat)];
        _lon = [decoder oba_decodeDouble:@selector(lon)];
        _latSpan = [decoder oba_decodeDouble:@selector(latSpan)];
        _lonSpan = [decoder oba_decodeDouble:@selector(lonSpan)];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder oba_encodeDouble:_lat forSelector:@selector(lat)];
    [encoder oba_encodeDouble:_lon forSelector:@selector(lon)];
    [encoder oba_encodeDouble:_latSpan forSelector:@selector(latSpan)];
    [encoder oba_encodeDouble:_lonSpan forSelector:@selector(lonSpan)];
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:self.class]) {
        return NO;
    }

    return self.lat == [object lat] &&
           self.lon == [object lon] &&
           self.latSpan == [object latSpan] &&
           self.lonSpan == [object lonSpan];
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%f_%f_%f_%f", self.lat, self.lon, self.latSpan, self.lonSpan] hash];
}

#pragma mark - NSObject

- (NSString*)description {
    return [self oba_description:@[@"lat", @"latSpan", @"lon", @"lonSpan"]];
}

@end

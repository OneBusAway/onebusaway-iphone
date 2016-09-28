//
//  OBARegionBoundsV2.m
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//

#import <OBAKit/OBARegionBoundsV2.h>
#import <OBAKit/NSObject+OBADescription.h>

@implementation OBARegionBoundsV2

static NSString * kLatKey = @"lat";
static NSString * kLatSpanKey = @"latSpan";
static NSString * kLonKey = @"lon";
static NSString * kLonSpanKey = @"lonSpan";

#pragma mark - NSCoder

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];

    if (self) {
        self.lat = [decoder decodeDoubleForKey:kLatKey];
        self.lon = [decoder decodeDoubleForKey:kLonKey];
        self.latSpan = [decoder decodeDoubleForKey:kLatSpanKey];
        self.lonSpan = [decoder decodeDoubleForKey:kLonSpanKey];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeDouble:self.lat forKey:kLatKey];
    [encoder encodeDouble:self.lon forKey:kLonKey];
    [encoder encodeDouble:self.latSpan forKey:kLatSpanKey];
    [encoder encodeDouble:self.lonSpan forKey:kLonSpanKey];
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

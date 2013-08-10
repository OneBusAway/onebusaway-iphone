//
//  OBARegionBoundsV2.m
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//

#import "OBARegionBoundsV2.h"

@implementation OBARegionBoundsV2
@synthesize lat;
@synthesize latSpan;
@synthesize lon;
@synthesize lonSpan;

static NSString * kLatKey = @"lat";
static NSString * kLatSpanKey = @"latSpan";
static NSString * kLonKey = @"lon";
static NSString * kLonSpanKey = @"lonSpan";

- (void) dealloc {
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeDouble:self.lat forKey:kLatKey];
    [encoder encodeDouble:self.lon forKey:kLonKey];
    [encoder encodeDouble:self.latSpan forKey:kLatSpanKey];
    [encoder encodeDouble:self.lonSpan forKey:kLonSpanKey];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self.lat = [decoder decodeDoubleForKey:kLatKey];
    self.lon = [decoder decodeDoubleForKey:kLonKey];
    self.latSpan = [decoder decodeDoubleForKey:kLatSpanKey];
    self.lonSpan = [decoder decodeDoubleForKey:kLonSpanKey];
    
    return self;
}


@end

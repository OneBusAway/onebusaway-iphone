//
//  OBARegionV2.m
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//

#import "OBARegionV2.h"
#import "OBARegionBoundsV2.h"

@implementation OBARegionV2
@synthesize siriBaseUrl;
@synthesize obaVersionInfo;
@synthesize supportsSiriRealtimeApis;
@synthesize language;
@synthesize supportsObaRealtimeApis;
@synthesize bounds = _bounds;
@synthesize supportsObaDiscoveryApis;
@synthesize contactEmail;
@synthesize twitterUrl;
@synthesize active;
@synthesize experimental;
@synthesize obaBaseUrl;
@synthesize id_number;
@synthesize regionName;

static NSString * kSiriBaseUrl = @"siriBaseUrl";
static NSString * kObaVersionInfo = @"obaVersionInfo";
static NSString * kSupportsSiriRealtimeApis = @"supportsSiriRealtimeApis";
static NSString * kLanguage = @"language";
static NSString * kSupportsObaRealtimeApis = @"supportsObaRealtimeApis";
static NSString * kBounds = @"bounds";
static NSString * kSupportsObaDiscoveryApis = @"supportsObaDiscoveryApis";
static NSString * kContactEmail = @"contactEmail";
static NSString * kTwitterUrl = @"twitterUrl";
static NSString * kFacebookUrl = @"facebookUrl";
static NSString * kActive = @"active";
static NSString * kExperimental = @"experimental";
static NSString * kObaBaseUrl = @"obaBaseUrl";
static NSString * kId_number = @"id_number";
static NSString * kRegionName = @"regionName";

- (id)init {
    self = [super init];
    if (self) {
        _bounds = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addBound:(OBARegionBoundsV2*)bound {
    [_bounds addObject:bound];
}

- (CLLocationDistance)distanceFromLocation:(CLLocation*)location {
    double distance = DBL_MAX;
    double lat = location.coordinate.latitude;
    double lon = location.coordinate.longitude;
    
    for (OBARegionBoundsV2 * bound in _bounds) {
        double thisDistance = DBL_MAX;
        if (bound.lat - bound.latSpan <= lat && lat <= bound.lat + bound.latSpan &&
            bound.lon - bound.lonSpan <= lon && lat <= bound.lon + bound.lonSpan) {
            thisDistance = 0;
        }
        else {
            CLLocation *boundLocation = [[CLLocation alloc] initWithLatitude:bound.lat longitude:bound.lon];
            thisDistance = [location distanceFromLocation:boundLocation];
        }
        if (thisDistance < distance) {
            distance = thisDistance;
        }
    }
    
    return distance;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.siriBaseUrl forKey:kSiriBaseUrl];
    [encoder encodeObject:self.obaVersionInfo forKey:kObaVersionInfo];
    [encoder encodeBool:self.supportsSiriRealtimeApis forKey:kSupportsSiriRealtimeApis];
    [encoder encodeObject:self.language forKey:kLanguage];
    [encoder encodeBool:self.supportsObaRealtimeApis forKey:kSupportsObaRealtimeApis];
    [encoder encodeObject:self.bounds forKey:kBounds];
    [encoder encodeBool:self.supportsObaDiscoveryApis forKey:kSupportsObaDiscoveryApis];
    [encoder encodeObject:self.contactEmail forKey:kContactEmail];
    [encoder encodeObject:self.twitterUrl forKey:kTwitterUrl];
    [encoder encodeObject:self.facebookUrl forKey:kFacebookUrl];
    [encoder encodeBool:self.active forKey:kActive];
    [encoder encodeBool:self.experimental forKey:kExperimental];
    [encoder encodeObject:self.obaBaseUrl forKey:kObaBaseUrl];
    [encoder encodeInteger:self.id_number forKey:kId_number];
    [encoder encodeObject:self.regionName forKey:kRegionName];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self.siriBaseUrl = [decoder decodeObjectForKey:kSiriBaseUrl];
    self.obaVersionInfo = [decoder decodeObjectForKey:kObaVersionInfo];
    self.supportsSiriRealtimeApis = [decoder decodeBoolForKey:kSupportsSiriRealtimeApis];
    self.language = [decoder decodeObjectForKey:kLanguage];
    self.supportsObaRealtimeApis = [decoder decodeBoolForKey:kSupportsObaRealtimeApis];
    self.bounds = [decoder decodeObjectForKey:kBounds];
    self.supportsObaRealtimeApis = [decoder decodeBoolForKey:kSupportsObaRealtimeApis];
    self.contactEmail = [decoder decodeObjectForKey:kContactEmail];
    self.twitterUrl = [decoder decodeObjectForKey:kTwitterUrl];
    self.facebookUrl = [decoder decodeObjectForKey:kFacebookUrl];
    self.active = [decoder decodeBoolForKey:kActive];
    self.experimental = [decoder decodeBoolForKey:kExperimental];
    self.obaBaseUrl = [decoder decodeObjectForKey:kObaBaseUrl];
    self.id_number = [decoder decodeIntegerForKey:kId_number];
    self.regionName = [decoder decodeObjectForKey:kRegionName];
    
    return self;
}


@end

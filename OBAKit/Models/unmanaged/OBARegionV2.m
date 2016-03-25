//
//  OBARegionV2.m
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//

#import "OBARegionV2.h"
#import "OBARegionBoundsV2.h"
#import "NSArray+OBAAdditions.h"

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
static NSString * kIdentifier = @"id_number";
static NSString * kRegionName = @"regionName";

@implementation OBARegionV2

- (id)init {
    self = [super init];
    if (self) {
        _bounds = @[];
    }
    return self;
}

#pragma mark - NSCoding

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
    [encoder encodeInteger:self.identifier forKey:kIdentifier];
    [encoder encodeObject:self.regionName forKey:kRegionName];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];

    if (self) {
        _siriBaseUrl = [decoder decodeObjectForKey:kSiriBaseUrl];
        _obaVersionInfo = [decoder decodeObjectForKey:kObaVersionInfo];
        _supportsSiriRealtimeApis = [decoder decodeBoolForKey:kSupportsSiriRealtimeApis];
        _language = [decoder decodeObjectForKey:kLanguage];
        _supportsObaRealtimeApis = [decoder decodeBoolForKey:kSupportsObaRealtimeApis];
        _bounds = [NSArray arrayWithArray:[decoder decodeObjectForKey:kBounds]];
        _supportsObaDiscoveryApis = [decoder decodeBoolForKey:kSupportsObaDiscoveryApis];
        _contactEmail = [decoder decodeObjectForKey:kContactEmail];
        _twitterUrl = [decoder decodeObjectForKey:kTwitterUrl];
        _facebookUrl = [decoder decodeObjectForKey:kFacebookUrl];
        _active = [decoder decodeBoolForKey:kActive];
        _experimental = [decoder decodeBoolForKey:kExperimental];
        _obaBaseUrl = [decoder decodeObjectForKey:kObaBaseUrl];
        _identifier = [decoder decodeIntegerForKey:kIdentifier];
        _regionName = [decoder decodeObjectForKey:kRegionName];
    }

    return self;
}

#pragma mark - Public Methods

- (void)addBound:(OBARegionBoundsV2*)bound {
    self.bounds = [self.bounds arrayByAddingObject:bound];
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

- (MKMapRect)serviceRect {
    double minX = DBL_MAX;
    double minY = DBL_MAX;
    double maxX = DBL_MIN;
    double maxY = DBL_MIN;
    for (OBARegionBoundsV2 *bounds in self.bounds) {
        MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(bounds.lat + bounds.latSpan / 2,
                                                                          bounds.lon - bounds.lonSpan / 2));
        MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(bounds.lat - bounds.latSpan / 2,
                                                                          bounds.lon + bounds.lonSpan / 2));
        minX = MIN(minX, MIN(a.x, b.x));
        minY = MIN(minY, MIN(a.y, b.y));
        maxX = MAX(maxX, MAX(a.x, b.x));
        maxY = MAX(maxY, MAX(a.y, b.y));
    }
    return MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
}

#pragma mark - NSObject

- (NSString*)description
{
    return [NSString stringWithFormat:@"<%@: %p> :: {%@ - obaBaseUrl: %@, bounds: %@, experimental: %@}", self.class, self, self.regionName, self.obaBaseUrl, self.bounds, self.experimental ? @"YES" : @"NO"];
}

@end

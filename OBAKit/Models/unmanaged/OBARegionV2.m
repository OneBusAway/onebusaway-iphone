//
//  OBARegionV2.m
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//

#import <OBAKit/OBARegionV2.h>
#import <OBAKit/OBARegionBoundsV2.h>
#import <OBAKit/NSArray+OBAAdditions.h>
#import <OBAKit/NSObject+OBADescription.h>

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
static NSString * kCustom = @"custom";

@implementation OBARegionV2
@dynamic baseURL;

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
    [encoder encodeBool:self.custom forKey:kCustom];
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
        _regionName = [self.class cleanUpRegionName:[decoder decodeObjectForKey:kRegionName]];
        _custom = [decoder decodeBoolForKey:kCustom];
    }

    return self;
}

#pragma mark - Region Name

- (void)setRegionName:(NSString *)regionName {
    _regionName = [self.class cleanUpRegionName:regionName];
}

+ (NSString*)cleanUpRegionName:(NSString*)regionName {
    if (regionName.length == 0) {
        return regionName;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\s?\\(?beta\\)?" options:NSRegularExpressionCaseInsensitive error:nil];
    return [regex stringByReplacingMatchesInString:regionName options:(NSMatchingOptions)0 range:NSMakeRange(0, regionName.length) withTemplate:@""];
}

#pragma mark - Other Public Methods

- (BOOL)isValidModel {
    return [self.baseURL.scheme isEqual:@"https"] && self.regionName.length > 0;
}

- (NSURL*)baseURL {
    return [NSURL URLWithString:self.obaBaseUrl];
}

#pragma mark - Public Location-Related Methods

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

- (NSComparisonResult)compare:(id)obj {
    if ([obj respondsToSelector:@selector(regionName)]) {
        return [self.regionName compare:[obj regionName]];
    }
    else {
        return NSOrderedAscending;
    }
}

- (NSUInteger)hash {
    return [NSString stringWithFormat:@"%@_%ld", NSStringFromClass(self.class), (long)self.identifier].hash;
}

- (BOOL)isEqual:(OBARegionV2*)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }

    if (![self.siriBaseUrl isEqual:object.siriBaseUrl]) {
        return NO;
    }

    if (![self.obaVersionInfo isEqual:object.obaVersionInfo]) {
        return NO;
    }

    if (![self.language isEqual:object.language]) {
        return NO;
    }

    if (![self.bounds isEqual:object.bounds]) {
        return NO;
    }

    if (![self.contactEmail isEqual:object.contactEmail]) {
        return NO;
    }

    if (![self.twitterUrl isEqual:object.twitterUrl]) {
        return NO;
    }

    if (![self.facebookUrl isEqual:object.facebookUrl]) {
        return NO;
    }

    if (![self.obaBaseUrl isEqual:object.obaBaseUrl]) {
        return NO;
    }
    
    if (![self.regionName isEqual:object.regionName]) {
        return NO;
    }

    if (self.supportsSiriRealtimeApis != object.supportsSiriRealtimeApis) {
        return NO;
    }

    if (self.supportsObaRealtimeApis != object.supportsObaRealtimeApis) {
        return NO;
    }

    if (self.supportsObaDiscoveryApis != object.supportsObaDiscoveryApis) {
        return NO;
    }

    if (self.active != object.active) {
        return NO;
    }

    if (self.experimental != object.experimental) {
        return NO;
    }

    if (self.identifier != object.identifier) {
        return NO;
    }

    if (self.custom != object.custom) {
        return NO;
    }

    return YES;
}

- (NSString*)description
{
    return [self oba_description:@[@"baseURL", @"custom", @"regionName", @"siriBaseUrl", @"obaVersionInfo", @"language", @"bounds", @"contactEmail", @"twitterUrl", @"facebookUrl", @"supportsSiriRealtimeApis", @"supportsObaRealtimeApis", @"supportsObaDiscoveryApis", @"active", @"experimental", @"identifier"]];
}

@end

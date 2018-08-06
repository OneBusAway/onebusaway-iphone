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
#import <OBAKit/NSCoder+OBAAdditions.h>

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
    [encoder oba_encodeBool:_active forSelector:@selector(active)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(bounds)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(contactEmail)];
    [encoder oba_encodeBool:_custom forSelector:@selector(custom)];
    [encoder oba_encodeBool:_experimental forSelector:@selector(experimental)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(facebookUrl)];
    [encoder oba_encodeInteger:_identifier forSelector:@selector(identifier)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(language)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(obaBaseUrl)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(obaVersionInfo)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(regionName)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(siriBaseUrl)];
    [encoder oba_encodeBool:_supportsObaRealtimeApis forSelector:@selector(supportsObaRealtimeApis)];
    [encoder oba_encodeBool:_supportsObaDiscoveryApis forSelector:@selector(supportsObaDiscoveryApis)];
    [encoder oba_encodeBool:_supportsSiriRealtimeApis forSelector:@selector(supportsSiriRealtimeApis)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(twitterUrl)];

    [encoder oba_encodePropertyOnObject:self withSelector:@selector(paymentWarningBody)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(paymentWarningTitle)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(paymentAppURLScheme)];
    [encoder oba_encodePropertyOnObject:self withSelector:@selector(paymentAppStoreIdentifier)];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];

    if (self) {
        _siriBaseUrl = [decoder oba_decodeObject:@selector(siriBaseUrl)];
        _obaVersionInfo = [decoder oba_decodeObject:@selector(obaVersionInfo)];
        _supportsSiriRealtimeApis = [decoder oba_decodeBool:@selector(supportsSiriRealtimeApis)];
        _language = [decoder oba_decodeObject:@selector(language)];

        _supportsObaRealtimeApis = [decoder oba_decodeBool:@selector(supportsObaRealtimeApis)];
        _bounds = [NSArray arrayWithArray:[decoder oba_decodeObject:@selector(bounds)]];
        _supportsObaDiscoveryApis = [decoder oba_decodeBool:@selector(supportsObaDiscoveryApis)];
        _contactEmail = [decoder oba_decodeObject:@selector(contactEmail)];
        _twitterUrl = [decoder oba_decodeObject:@selector(twitterUrl)];
        _facebookUrl = [decoder oba_decodeObject:@selector(facebookUrl)];
        _active = [decoder oba_decodeBool:@selector(active)];
        _experimental = [decoder oba_decodeBool:@selector(experimental)];
        _obaBaseUrl = [decoder oba_decodeObject:@selector(obaBaseUrl)];
        _identifier = [decoder oba_decodeInteger:@selector(identifier)];
        _regionName = [self.class cleanUpRegionName:[decoder oba_decodeObject:@selector(regionName)]];
        _custom = [decoder oba_decodeBool:@selector(custom)];

        _paymentWarningBody = [decoder oba_decodeObject:@selector(paymentWarningBody)];
        _paymentWarningTitle = [decoder oba_decodeObject:@selector(paymentWarningTitle)];
        _paymentAppURLScheme = [decoder oba_decodeObject:@selector(paymentAppURLScheme)];
        _paymentAppStoreIdentifier = [decoder oba_decodeObject:@selector(paymentAppStoreIdentifier)];
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

#pragma mark - Payment App

- (void)setPaymentWarningBody:(NSString*)body {
    if (body == (id)NSNull.null) {
        _paymentWarningBody = nil;
    }
    else {
        _paymentWarningBody = [body copy];
    }
}

- (void)setPaymentWarningTitle:(NSString*)title {
    if (title == (id)NSNull.null) {
        _paymentWarningTitle = nil;
    }
    else {
        _paymentWarningTitle = [title copy];
    }
}

- (void)setPaymentAppURLScheme:(NSString*)scheme {
    if (scheme == (id)NSNull.null) {
        _paymentAppURLScheme = nil;
    }
    else {
        _paymentAppURLScheme = [scheme copy];
    }
}

- (void)setPaymentAppStoreIdentifier:(NSString*)appID {
    if (appID == (id)NSNull.null) {
        _paymentAppStoreIdentifier = nil;
    }
    else {
        _paymentAppStoreIdentifier = [appID copy];
    }
}

- (BOOL)supportsMobileFarePayment {
    return self.paymentAppURLScheme != nil;
}

- (BOOL)paymentAppDoesNotCoverFullRegion {
    return self.paymentWarningTitle != nil && self.paymentWarningBody != nil;
}

- (NSURL*)paymentAppDeepLinkURL {
    if (self.supportsMobileFarePayment) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@://open", self.paymentAppURLScheme]];
    }
    else {
        return nil;
    }
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

- (CLLocationCoordinate2D)centerCoordinate {
    MKMapRect rect = self.serviceRect;
    MKMapPoint centerPoint = MKMapPointMake(MKMapRectGetMidX(rect), MKMapRectGetMidY(rect));

    return MKCoordinateForMapPoint(centerPoint);
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

    if (![self.paymentWarningBody isEqual:object.paymentWarningBody]) {
        return NO;
    }

    if (![self.paymentWarningTitle isEqual:object.paymentWarningTitle]) {
        return NO;
    }

    if (![self.paymentAppURLScheme isEqual:object.paymentAppURLScheme]) {
        return NO;
    }

    if (![self.paymentAppStoreIdentifier isEqual:object.paymentAppStoreIdentifier]) {
        return NO;
    }

    return YES;
}

- (NSString*)description
{
    return [self oba_description:@[@"baseURL", @"custom", @"regionName", @"siriBaseUrl", @"obaVersionInfo", @"language", @"bounds", @"contactEmail", @"twitterUrl", @"facebookUrl", @"supportsSiriRealtimeApis", @"supportsObaRealtimeApis", @"supportsObaDiscoveryApis", @"active", @"experimental", @"identifier", @"paymentWarningBody", @"paymentWarningTitle", @"paymentAppURLScheme", @"paymentAppStoreIdentifier"]];
}

@end

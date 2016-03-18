//
//  OBAMapHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/27/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAMapHelpers.h"
#import "OBACoordinateBounds.h"
#import "OBAAgencyWithCoverageV2.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBAStopV2.h"
#import "OBAPlacemark.h"
#import "OBARegionBoundsV2.h"

const double OBADefaultMapRadiusInMeters = 100;
const double OBAMinMapRadiusInMeters = 150;
//const double OBAMaxLatitudeDeltaToShowStops = 0.008;
const double OBAMaxLatitudeDeltaToShowStops = 0.05;
const double OBARegionScaleFactor = 1.5;
const double OBARegionZoomLevelThreshold = 1;
const double OBAMaxMapDistanceFromCurrentLocationForNearby = 800;
const double OBAPaddingScaleFactor = 1.075;

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395
#define MAXIMUM_ZOOM                20

NSInteger OBASortStopsByDistanceFromLocation(OBAStopV2 *stop1, OBAStopV2 *stop2, void *context) {
    CLLocation *location = (__bridge CLLocation *)context;

    CLLocation *stopLocation1 = [[CLLocation alloc] initWithLatitude:stop1.lat longitude:stop1.lon];
    CLLocation *stopLocation2 = [[CLLocation alloc] initWithLatitude:stop2.lat longitude:stop2.lon];

    CLLocationDistance v1 = [location distanceFromLocation:stopLocation1];
    CLLocationDistance v2 = [location distanceFromLocation:stopLocation2];

    if (v1 < v2) {
        return NSOrderedAscending;
    }
    else if (v1 > v2) {
        return NSOrderedDescending;
    }
    else {
        return NSOrderedSame;
    }
}

@implementation OBAMapHelpers

#pragma mark - Map conversion methods

+ (double)longitudeToPixelSpaceX:(double)longitude
{
    return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

+ (double)latitudeToPixelSpaceY:(double)latitude
{
    return round(MERCATOR_OFFSET - MERCATOR_RADIUS * log((1 + sin(latitude * M_PI / 180.0)) / (1 - sin(latitude * M_PI / 180.0))) / 2.0);
}

+ (double)pixelSpaceXToLongitude:(double)pixelX
{
    return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

+ (double)pixelSpaceYToLatitude:(double)pixelY
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
}

#pragma mark - Helper methods

+ (MKCoordinateSpan)coordinateSpanWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel viewSize:(CGSize)size
{
    // convert center coordiate to pixel space
    double centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
    double centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];

    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);

    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;

    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);

    // find delta between left and right longitudes
    CLLocationDegrees minLng = [self.class pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [self.class pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;

    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = [self.class pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [self.class pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);

    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}

+ (MKCoordinateRegion)coordinateRegionWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel viewSize:(CGSize)size
{
    return MKCoordinateRegionMake(centerCoordinate, [self coordinateSpanWithCenterCoordinate:centerCoordinate zoomLevel:zoomLevel viewSize:size]);
}

+ (NSString*)stringFromDistance:(CLLocationDistance)distance {
    static MKDistanceFormatter *formatter = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[MKDistanceFormatter alloc] init];
    });

    return [formatter stringFromDistance:distance];
}

+ (CLLocationDistance)getDistanceFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end {
    CLLocation *startLoc = [[CLLocation alloc] initWithLatitude:start.latitude longitude:start.longitude];
    CLLocation *endLoc = [[CLLocation alloc] initWithLatitude:end.latitude longitude:end.longitude];
    CLLocationDistance distance = [startLoc distanceFromLocation:endLoc];

    return distance;
}

+ (CLCircularRegion*)convertVisibleMapRect:(MKMapRect)visibleMapRect intoCircularRegionWithCenter:(CLLocationCoordinate2D)centerCoordinate {
    MKMapPoint neMapPoint = MKMapPointMake(MKMapRectGetMaxX(visibleMapRect), visibleMapRect.origin.y);
    MKMapPoint swMapPoint = MKMapPointMake(visibleMapRect.origin.x, MKMapRectGetMaxY(visibleMapRect));
    CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
    CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
    CLLocationDistance diameter = [OBAMapHelpers getDistanceFrom:neCoord to:swCoord];

    return [[CLCircularRegion alloc] initWithCenter:centerCoordinate radius:(diameter / 2.0) identifier:@"mapRegion"];
}

+ (MKMapRect)mapRectForCoordinateRegion:(MKCoordinateRegion)region {
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude + region.span.latitudeDelta / 2,
                                                                      region.center.longitude - region.span.longitudeDelta / 2));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude - region.span.latitudeDelta / 2,
                                                                      region.center.longitude + region.span.longitudeDelta / 2));

    return MKMapRectMake(MIN(a.x, b.x), MIN(a.y, b.y), ABS(a.x - b.x), ABS(a.y - b.y));
}

+ (MKCoordinateRegion)computeRegionForAgenciesWithCoverage:(NSArray*)agenciesWithCoverage defaultRegion:(MKCoordinateRegion)defaultRegion {
    if (0 == agenciesWithCoverage.count) {
        return defaultRegion;
    }

    OBACoordinateBounds *bounds = [OBACoordinateBounds bounds];

    for (OBAAgencyWithCoverageV2 *agencyWithCoverage in agenciesWithCoverage) {
        [bounds addCoordinate:agencyWithCoverage.coordinate];
    }

    if (bounds.empty) {
        return defaultRegion;
    }

    MKCoordinateRegion region = bounds.region;
    MKCoordinateRegion minRegion = [OBASphericalGeometryLibrary createRegionWithCenter:region.center latRadius:50000 lonRadius:50000];

    if (region.span.latitudeDelta < minRegion.span.latitudeDelta) {
        region.span.latitudeDelta = minRegion.span.latitudeDelta;
    }

    if (region.span.longitudeDelta < minRegion.span.longitudeDelta) {
        region.span.longitudeDelta = minRegion.span.longitudeDelta;
    }

    return region;
}

+ (MKCoordinateRegion)computeRegionForStops:(NSArray *)stops center:(CLLocation *)location {
    CLLocationCoordinate2D center = location.coordinate;

    MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:center latRadius:OBADefaultMapRadiusInMeters lonRadius:OBADefaultMapRadiusInMeters];
    MKCoordinateSpan span = region.span;

    for (OBAStopV2 *stop in stops) {
        double latDelta = ABS(stop.lat - center.latitude) * 2.0 * OBAPaddingScaleFactor;
        double lonDelta = ABS(stop.lon - center.longitude) * 2.0 * OBAPaddingScaleFactor;

        span.latitudeDelta  = MAX(span.latitudeDelta, latDelta);
        span.longitudeDelta = MAX(span.longitudeDelta, lonDelta);
    }

    region.center = center;
    region.span = span;

    return region;
}

+ (MKCoordinateRegion)computeRegionForPlacemarks:(NSArray<OBAPlacemark*>*)placemarks defaultRegion:(MKCoordinateRegion)defaultRegion {
    OBACoordinateBounds *bounds = [OBACoordinateBounds bounds];

    for (OBAPlacemark *placemark in placemarks) {
        [bounds addCoordinate:placemark.coordinate];
    }

    if (bounds.empty) {
        return defaultRegion;
    }

    return bounds.region;
}

+ (BOOL)visibleMapRect:(MKMapRect)visibleMapRect isOutOfServiceArea:(NSArray<OBARegionBoundsV2*>*)serviceArea {

    for (OBARegionBoundsV2 *bounds in serviceArea) {
        MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(bounds.lat + bounds.latSpan / 2,
                                                                          bounds.lon - bounds.lonSpan / 2));
        MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(bounds.lat - bounds.latSpan / 2,
                                                                          bounds.lon + bounds.lonSpan / 2));

        MKMapRect serviceRect = MKMapRectMake(MIN(a.x, b.x), MIN(a.y, b.y), ABS(a.x - b.x), ABS(a.y - b.y));

        if (MKMapRectIntersectsRect(serviceRect, visibleMapRect)) {
            return NO;
        }
    }

    return YES;
}

+ (MKCoordinateRegion)computeRegionForNClosestStops:(NSArray *)stops center:(CLLocation *)location numberOfStops:(NSUInteger)numberOfStops {
    NSMutableArray *stopsSortedByDistance = [NSMutableArray arrayWithArray:stops];

    [stopsSortedByDistance sortUsingFunction:OBASortStopsByDistanceFromLocation context:(__bridge void *)(location)];

    while ([stopsSortedByDistance count] > numberOfStops) {
        [stopsSortedByDistance removeLastObject];
    }

    return [OBAMapHelpers computeRegionForStops:stopsSortedByDistance center:location];
}


+ (MKCoordinateRegion)computeRegionForStops:(NSArray*)stops {
    double latRun = 0.0, lonRun = 0.0;

    for (OBAStopV2 *stop in stops) {
        latRun += stop.lat;
        lonRun += stop.lon;
    }

    CLLocationCoordinate2D center;
    center.latitude = latRun / stops.count;
    center.longitude = lonRun / stops.count;

    CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];

    return [OBAMapHelpers computeRegionForStops:stops center:centerLocation];
}

+ (MKCoordinateRegion)computeRegionForCenter:(CLLocation*)center nearbyStops:(NSArray*)stops {
    NSMutableArray *stopsInRange = [NSMutableArray array];

    for (OBAStopV2 *stop in stops) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:stop.lat longitude:stop.lon];
        CLLocationDistance d = [location distanceFromLocation:center];

        if (d < OBAMaxMapDistanceFromCurrentLocationForNearby) {
            [stopsInRange addObject:stop];
        }
    }

    if (stopsInRange.count > 0) {
        return [OBAMapHelpers computeRegionForStops:stopsInRange center:center];
    }
    else {
        return [OBAMapHelpers computeRegionForStops:stops];
    }
}

+ (NSUInteger)zoomLevelForMapRect:(MKMapRect)mRect withMapViewSizeInPixels:(CGSize)viewSizeInPixels
{
    NSUInteger zoomLevel = MAXIMUM_ZOOM;
    MKZoomScale zoomScale = mRect.size.width / viewSizeInPixels.width; //MKZoomScale is just a CGFloat typedef
    double zoomExponent = log2(zoomScale);
    zoomLevel = (NSUInteger)(MAXIMUM_ZOOM - ceil(zoomExponent));
    return zoomLevel;
}

@end
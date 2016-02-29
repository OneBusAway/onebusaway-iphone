//
//  OBAMapHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/27/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAMapHelpers.h"

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395

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
@end
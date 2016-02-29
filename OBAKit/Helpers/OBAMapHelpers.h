//
//  OBAMapHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/27/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface OBAMapHelpers : NSObject

+ (double)longitudeToPixelSpaceX:(double)longitude;
+ (double)latitudeToPixelSpaceY:(double)latitude;
+ (double)pixelSpaceXToLongitude:(double)pixelX;
+ (double)pixelSpaceYToLatitude:(double)pixelY;
+ (MKCoordinateSpan)coordinateSpanWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel viewSize:(CGSize)size;
+ (MKCoordinateRegion)coordinateRegionWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel viewSize:(CGSize)size;

+ (NSString*)stringFromDistance:(CLLocationDistance)distance;
@end
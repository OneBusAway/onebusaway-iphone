//
//  OBAMapHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/27/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import MapKit;

NS_ASSUME_NONNULL_BEGIN

extern const double OBADefaultMapRadiusInMeters;
extern const double OBAMinMapRadiusInMeters;
extern const double OBAMaxLatitudeDeltaToShowStops;
extern const double OBARegionScaleFactor;
extern const double OBAMaxMapDistanceFromCurrentLocationForNearby;
extern const double OBAPaddingScaleFactor;
extern const double OBARegionZoomLevelThreshold;

@class OBAPlacemark;
@class OBARegionBoundsV2;
@class OBAStopV2;
@class OBABookmarkV2;

NSInteger OBASortStopsByDistanceFromLocation(OBAStopV2 *stop1, OBAStopV2 *stop2, void *context);

NSInteger OBASortBookmarksByDistanceFromLocation(OBABookmarkV2 *bm1, OBABookmarkV2 *bm2, void *context);

@interface OBAMapHelpers : NSObject

+ (MKCoordinateSpan)coordinateSpanWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel viewSize:(CGSize)size;
+ (MKCoordinateRegion)coordinateRegionWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel viewSize:(CGSize)size;

+ (NSString*)stringFromDistance:(CLLocationDistance)distance;

/**
 Converts an MKCoordinateRegion

 @param coordinateRegion A coordinate region
 @return The equivalent circular region
 */
+ (CLCircularRegion*)convertCoordinateRegionToCircularRegion:(MKCoordinateRegion)coordinateRegion;

/**
 Computes distance between two CLLocationCoordinate2D points.

 @param start Start coordinate
 @param end   End coordinate

 @return The distance between the two points
 */
+ (CLLocationDistance)getDistanceFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end;

/**
 Converts an MKMapView's visibleMapRect property with centerCoordinate into a CLCircularRegion.

 @param visibleMapRect   The visibleMapRect property from an instance of MKMapView.
 @param centerCoordinate The centerCoordinate property from an instance of MKMapView.

 @return A CLCircularRegion bounding visibleMapRect, centered on centerCoordinate.
 */
+ (CLCircularRegion*)convertVisibleMapRect:(MKMapRect)visibleMapRect intoCircularRegionWithCenter:(CLLocationCoordinate2D)centerCoordinate;

/**
 Converts an MKCoordinateRegion into an MKMapRect.

 @param region The MKCoordinateRegion, such as one returned from -[MKMapView convertRect:toRegionFromView:]

 @return The equivalent MKMapRect.
 */
+ (MKMapRect)mapRectForCoordinateRegion:(MKCoordinateRegion)region;

/**
 Calculate the coordinate region for the list of stops provided with a provided center location.

 @param stops    The list of stops from which to calculate a region.
 @param location The center point of the region.

 @return The coordinate region that can be used to position the map.
 */
+ (MKCoordinateRegion)computeRegionForStops:(NSArray *)stops center:(CLLocation *)location;

/**
 Calculate the coordinate region for the list of placemarks provided. Falls back to the default region if it cannot compute a region from the placemarks.

 @param placemarks    The list of `OBAPlacemark`s that it will compute a region from.
 @param defaultRegion The fallback MKCoordinateRegion that will be returned if `OBAPlacemark`s are empty.

 @return The bounding region for the provided placemarks.
 */
+ (MKCoordinateRegion)computeRegionForPlacemarks:(NSArray<OBAPlacemark*>*)placemarks defaultRegion:(MKCoordinateRegion)defaultRegion;

/**
 Determine whether the specified visibleMapRect is outside of the bounds of the aray of OBARegionBoundsV2 objects.

 @param visibleMapRect The visible area of a map: -[MKMapView visibleMapRect]
 @param serviceArea    An array of OBARegionBoundsV2 objects.

 @return Whether the visible map rect intersects the service area or not.
 */
+ (BOOL)visibleMapRect:(MKMapRect)visibleMapRect isOutOfServiceArea:(NSArray<OBARegionBoundsV2*>*)serviceArea;

+ (MKCoordinateRegion)computeRegionForNClosestStops:(NSArray *)stops center:(CLLocation *)location numberOfStops:(NSUInteger)numberOfStops;
+ (MKCoordinateRegion)computeRegionForStops:(NSArray*)stops;
+ (MKCoordinateRegion)computeRegionForCenter:(CLLocation*)center nearbyStops:(NSArray*)stops;
+ (NSUInteger)zoomLevelForMapRect:(MKMapRect)mRect withMapViewSizeInPixels:(CGSize)viewSizeInPixels;
@end

NS_ASSUME_NONNULL_END

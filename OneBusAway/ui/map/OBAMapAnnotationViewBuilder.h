//
//  OBAMapAnnotationViewBuilder.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/2/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import MapKit;
@import OBAKit;

@interface OBAMapAnnotationViewBuilder : NSObject
+ (MKAnnotationView*)viewForAnnotation:(id<MKAnnotation>)annotation forMapView:(MKMapView*)mapView;
+ (MKAnnotationView*)mapView:(MKMapView*)mapView annotationViewForStop:(OBAStopV2*)stop withSearchType:(OBASearchType)searchType;
+ (MKAnnotationView*)mapView:(MKMapView*)mapView annotationViewForBookmark:(OBABookmarkV2*)bookmark;
+ (MKAnnotationView*)mapView:(MKMapView *)mapView viewForPlacemark:(OBAPlacemark*)placemark withSearchType:(OBASearchType)searchType;
+ (MKAnnotationView*)mapView:(MKMapView *)mapView viewForNavigationTarget:(OBANavigationTargetAnnotation*)annotation;
+ (void)updateAnnotationsOnMapView:(MKMapView*)mapView fromSearchResult:(OBASearchResult*)result bookmarkAnnotations:(NSArray*)bookmarks;
+ (void)setOverlaysOnMapView:(MKMapView*)mapView fromSearchResult:(OBASearchResult*)result;
@end

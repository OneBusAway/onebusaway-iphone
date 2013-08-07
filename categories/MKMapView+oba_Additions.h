//
//  MKMapView+oba_Additions.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/22/12.
//
//

// From http://troybrant.net/blog/2010/01/set-the-zoom-level-of-an-mkmapview/

#import <MapKit/MapKit.h>

@interface MKMapView (oba_Additions)
- (void)oba_setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel animated:(BOOL)animated;
@end
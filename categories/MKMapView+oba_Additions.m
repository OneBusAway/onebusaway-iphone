//
//  MKMapView+oba_Additions.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/22/12.
//
//

#import "MKMapView+oba_Additions.h"
#import <OBAKit/OBAMapHelpers.h>

@implementation MKMapView (oba_Additions)

- (MKCoordinateSpan)oba_coordinateSpanWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel
{
    return [OBAMapHelpers coordinateSpanWithCenterCoordinate:centerCoordinate zoomLevel:zoomLevel viewSize:self.bounds.size];
}

- (void)oba_setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel animated:(BOOL)animated
{
    // clamp large numbers to 28
    zoomLevel = MIN(zoomLevel, 28);
    
    // use the zoom level to compute the region
    MKCoordinateSpan span = [self oba_coordinateSpanWithCenterCoordinate:centerCoordinate zoomLevel:zoomLevel];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self setRegion:region animated:animated];
}

@end

//
//  OBAMapAnnotationViewBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/2/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBAMapAnnotationViewBuilder.h"

@implementation OBAMapAnnotationViewBuilder

+ (MKAnnotationView*)viewForAnnotation:(id<MKAnnotation>)annotation forMapView:(MKMapView*)mapView {

    NSString *reuseIdentifier = NSStringFromClass([annotation class]);

    MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];

    if (!view) {
        view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    }

    view.canShowCallout = NO;
    view.rightCalloutAccessoryView = ({
        UIButton *rightCalloutButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightCalloutButton setImage:[UIImage imageNamed:@"chevron"] forState:UIControlStateNormal];
        if ([OBATheme useHighContrastUI]) {
            rightCalloutButton.tintColor = [UIColor blackColor];
        }
        else {
            rightCalloutButton.tintColor = [OBATheme OBAGreen];
        }
        rightCalloutButton;
    });

    return view;
}

+ (MKAnnotationView*)mapView:(MKMapView*)mapView annotationViewForStop:(OBAStopV2*)stop withSearchType:(OBASearchType)searchType {
    MKAnnotationView *view = [OBAMapAnnotationViewBuilder viewForAnnotation:stop forMapView:mapView];
    view.image = [OBAStopIconFactory getIconForStop:stop];

    return view;
}

+ (MKAnnotationView*)mapView:(MKMapView*)mapView annotationViewForBookmark:(OBABookmarkV2*)bookmark {
    MKAnnotationView *view = [self.class viewForAnnotation:bookmark forMapView:mapView];

    UIImage *stopImage = nil;

    if (bookmark.stop) {
        stopImage = [OBAStopIconFactory getIconForStop:bookmark.stop];
        stopImage = [OBAImageHelpers colorizeImage:stopImage withColor:[OBATheme mapBookmarkTintColor]];
    }
    else {
        stopImage = [UIImage imageNamed:@"Bookmarks"];
    }

    view.image = stopImage;

    return view;
}

+ (MKAnnotationView*)mapView:(MKMapView *)mapView viewForPlacemark:(OBAPlacemark*)placemark withSearchType:(OBASearchType)searchType {
    static NSString *viewId = @"NavigationTargetView";
    MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

    if (!view) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:placemark reuseIdentifier:viewId];
    }

    view.canShowCallout = YES;

    if (OBASearchTypeAddress == searchType) {
        view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    else {
        view.rightCalloutAccessoryView = nil;
    }

    return view;
}

+ (MKAnnotationView*)mapView:(MKMapView *)mapView viewForNavigationTarget:(OBANavigationTargetAnnotation*)annotation {
    static NSString *viewId = @"NavigationTargetView";
    MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

    if (!view) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
    }

    OBANavigationTargetAnnotation *nav = annotation;

    view.canShowCallout = YES;

    if (nav.target) {
        view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    else {
        view.rightCalloutAccessoryView = nil;
    }
    
    return view;
}

/* I feel like 2/3's of this method could be replaced
 by using an NSSet instead of an array. Something to
 consider going forward. */
+ (void)updateAnnotationsOnMapView:(MKMapView*)mapView fromSearchResult:(OBASearchResult*)result bookmarkAnnotations:(NSArray*)bookmarks {
    NSMutableArray *allCurrentAnnotations = [[NSMutableArray alloc] init];

    NSSet *bookmarkStopIDs = nil;

    if (result.searchType != OBASearchTypeStopIdSearch && result.searchType != OBASearchTypeRoute) {
        [allCurrentAnnotations addObjectsFromArray:bookmarks];
        bookmarkStopIDs = [NSSet setWithArray:[bookmarks valueForKey:@"stopId"]];
    }
    else {
        bookmarkStopIDs = [NSSet set];
    }

    // prospectiveAnnotation *should* be an OBAStopV2, but there are some indications that this
    // is not always the case. To that end, we'll just go belt and suspenders on it and see if
    // the object responds to the appropriate selector. Additionally, I've added a type check
    // to validate my own assumptions about this.
    // https://github.com/OneBusAway/onebusaway-iphone/issues/825
    for (id prospectiveAnnotation in result.values) {
        OBAGuardClass(prospectiveAnnotation, OBAStopV2) else {
            DDLogError(@"prospectiveAnnotation is an instance of %@, and not OBAStopV2!", NSStringFromClass([prospectiveAnnotation class]));
        }

        if (![prospectiveAnnotation respondsToSelector:@selector(stopId)]) {
            continue;
        }

        NSString *stopID = [prospectiveAnnotation stopId];

        if ([bookmarkStopIDs containsObject:stopID]) {
            continue;
        }

        [allCurrentAnnotations addObject:prospectiveAnnotation];
    }

    NSMutableArray *toAdd = [[NSMutableArray alloc] init];
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];

    for (id<MKAnnotation> installedAnnotation in mapView.annotations) {

        if ([installedAnnotation isKindOfClass:[MKUserLocation class]]) {
            continue;
        }

        if (![allCurrentAnnotations containsObject:installedAnnotation]) {
            [toRemove addObject:installedAnnotation];
        }
    }

    for (id annotation in allCurrentAnnotations) {
        if (![mapView.annotations containsObject:annotation]) {
            [toAdd addObject:annotation];
        }
    }

    DDLogInfo(@"Annotations to remove: %@", @(toRemove.count));
    DDLogInfo(@"Annotations to add: %@", @(toAdd.count));

    [mapView removeAnnotations:toRemove];
    [mapView addAnnotations:toAdd];
}

+ (void)setOverlaysOnMapView:(MKMapView*)mapView fromSearchResult:(OBASearchResult*)result {
    [mapView removeOverlays:mapView.overlays];

    if (result && result.searchType == OBASearchTypeStops) {
        for (NSString *polylineString in result.additionalValues) {
            MKPolyline *polyline = [OBASphericalGeometryLibrary decodePolylineStringAsMKPolyline:polylineString];
            [mapView addOverlay:polyline];
        }
    }
}

@end

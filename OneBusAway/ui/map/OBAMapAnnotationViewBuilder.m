//
//  OBAMapAnnotationViewBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/2/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBAMapAnnotationViewBuilder.h"
#import "OneBusAway-Swift.h"

@implementation OBAMapAnnotationViewBuilder

+ (MKAnnotationView*)viewForAnnotation:(id<MKAnnotation>)annotation forMapView:(MKMapView*)mapView {
    NSString *reuseIdentifier = NSStringFromClass(annotation.class);

    OBAStopAnnotationView *view = (OBAStopAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];

    if (!view) {
        view = [[OBAStopAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        // todo: find a better way of plumbing this in at some point. :-|
        view.showsSelectionState = [[OBAApplication sharedApplication].userDefaults boolForKey:OBAUseStopDrawerDefaultsKey];
    }

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

    view.annotation = annotation;

    return view;
}

+ (MKPinAnnotationView*)navigationTargetAnnotationViewWithAnnotation:(id<MKAnnotation>)annotation mapView:(MKMapView*)mapView {
    static NSString *viewId = @"NavigationTargetView";
    MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

    if (!view) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
    }

    view.annotation = annotation;

    view.rightCalloutAccessoryView = nil;
    view.canShowCallout = YES;

    return view;
}

+ (MKAnnotationView*)mapView:(MKMapView *)mapView viewForPlacemark:(OBAPlacemark*)placemark withSearchType:(OBASearchType)searchType {
    MKPinAnnotationView *annotationView = [self navigationTargetAnnotationViewWithAnnotation:placemark mapView:mapView];

    if (OBASearchTypeAddress == searchType) {
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }

    return annotationView;
}

+ (MKAnnotationView*)mapView:(MKMapView *)mapView viewForNavigationTarget:(OBANavigationTargetAnnotation*)annotation {
    MKPinAnnotationView *annotationView = [self navigationTargetAnnotationViewWithAnnotation:annotation mapView:mapView];

    if (annotation.target) {
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }

    return annotationView;
}

/* I feel like 2/3's of this method could be replaced
 by using an NSSet instead of an array. Something to
 consider going forward. */
+ (void)updateAnnotationsOnMapView:(MKMapView*)mapView fromSearchResult:(OBASearchResult*)result bookmarkAnnotations:(NSArray*)bookmarks {
    NSMutableArray *allCurrentAnnotations = [[NSMutableArray alloc] init];

    NSSet *bookmarkStopIDs = [NSSet set];

    if (result.searchType != OBASearchTypeStopIdSearch && result.searchType != OBASearchTypeRoute) {
        [allCurrentAnnotations addObjectsFromArray:bookmarks];
        bookmarkStopIDs = [NSSet setWithArray:[bookmarks valueForKey:@"stopId"]];
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
            MKPolyline *polyline = [OBASphericalGeometryLibrary polylineFromEncodedShape:polylineString];
            [mapView addOverlay:polyline];
        }
    }
}

@end

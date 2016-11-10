//
//  OBAWalkingDirections.m
//  OBAKit
//
//  Created by Aaron Brethorst on 11/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAWalkingDirections.h>
@import MapKit;
@import PMKCoreLocation;
@import PMKMapKit;

@implementation OBAWalkingDirections

+ (AnyPromise*)requestWalkingETA:(CLLocationCoordinate2D)destination {
    __block NSUInteger iterations = 0;
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [CLLocationManager until:^BOOL(CLLocation *location) {
            iterations += 1;
            if (iterations >= 5) {
                return YES;
            }
            else {
                return location.horizontalAccuracy <= kCLLocationAccuracyNearestTenMeters;
            }
        }].thenInBackground(^(CLLocation* currentLocation) {
            MKPlacemark *sourcePlacemark = [self.class placemarkForCoordinate:currentLocation.coordinate];
            MKPlacemark *destinationPlacemark = [self.class placemarkForCoordinate:destination];
            MKDirections *directions = [self.class walkingDirectionsFrom:sourcePlacemark to:destinationPlacemark];
            return [directions calculateETA];
        }).then(^(MKETAResponse* ETA) {
            resolve(ETA);
        }).catch(^(NSError *error) {
            resolve(error);
        }).always(^{
            iterations = 0;
        });
    }];
}

+ (MKPlacemark*)placemarkForCoordinate:(CLLocationCoordinate2D)coordinate {
    return [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
}

+ (MKDirections*)walkingDirectionsFrom:(MKPlacemark*)fromPlacemark to:(MKPlacemark*)toPlacemark {
    return [[MKDirections alloc] initWithRequest:({
        MKDirectionsRequest *r = [[MKDirectionsRequest alloc] init];
        r.source = [[MKMapItem alloc] initWithPlacemark:fromPlacemark];
        r.destination = [[MKMapItem alloc] initWithPlacemark:toPlacemark];
        r.transportType = MKDirectionsTransportTypeWalking;
        r;
    })];
}

@end

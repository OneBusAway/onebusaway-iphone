//
//  OBAWalkingDirections.m
//  OBAKit
//
//  Created by Aaron Brethorst on 11/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAWalkingDirections.h>
@import MapKit;
#import <OBAKit/OBALogging.h>
#import <OBAKit/OBACommon.h>

@implementation OBAWalkingDirections

+ (MKDirections*)directionsFromCoordinate:(CLLocationCoordinate2D)from toCoordinate:(CLLocationCoordinate2D)to {
    MKPlacemark *sourcePlacemark = [self placemarkForCoordinate:from];
    MKPlacemark *destinationPlacemark = [self placemarkForCoordinate:to];
    MKDirections *directions = [self walkingDirectionsFrom:sourcePlacemark to:destinationPlacemark];

    return directions;
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

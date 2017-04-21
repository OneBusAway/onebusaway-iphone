//
//  OBAWalkingDirections.h
//  OBAKit
//
//  Created by Aaron Brethorst on 11/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import CoreLocation;
@import MapKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBAWalkingDirections : NSObject
+ (MKDirections*)directionsFromCoordinate:(CLLocationCoordinate2D)from toCoordinate:(CLLocationCoordinate2D)to;

/**
 Calculates the travel time in seconds from one location to another, assuming a normal human 
 walking speed of 1.4 meters per second (about 3.1 miles per hour).

 @param from From location
 @param to To location
 @return Walking time in seconds
 */
+ (NSTimeInterval)walkingTravelTimeFromLocation:(CLLocation*)from toLocation:(CLLocation*)to;
@end

NS_ASSUME_NONNULL_END

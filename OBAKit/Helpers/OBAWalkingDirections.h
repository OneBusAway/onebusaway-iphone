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
@end

NS_ASSUME_NONNULL_END

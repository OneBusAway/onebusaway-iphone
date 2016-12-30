//
//  OBAWalkingDirections.h
//  OBAKit
//
//  Created by Aaron Brethorst on 11/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import CoreLocation;
@import PromiseKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBAWalkingDirections : NSObject
/**
 Resolves to an MKETAResponse object.
 */
+ (AnyPromise*)requestWalkingETA:(CLLocationCoordinate2D)destination;
@end

NS_ASSUME_NONNULL_END

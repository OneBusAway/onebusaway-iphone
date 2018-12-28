//
//  OBAOccupancyStatus.h
//  OBAKit
//
//  Created by Aaron Brethorst on 12/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import Foundation;

NS_SWIFT_NAME(OccupancyStatus)
typedef NS_ENUM(NSUInteger, OBAOccupancyStatus) {
    OBAOccupancyStatusUnknown = 0,
    OBAOccupancyStatusEmpty,
    OBAOccupancyStatusManySeatsAvailable,
    OBAOccupancyStatusFewSeatsAvailable,
    OBAOccupancyStatusStandingRoomOnly,
    OBAOccupancyStatusCrushedStandingRoomOnly,
    OBAOccupancyStatusFull,
    OBAOccupancyStatusNotAcceptingPassengers,
};

extern OBAOccupancyStatus OBAStringToOccupancyStatus(NSString * stringValue);

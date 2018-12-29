//
//  OBAOccupancyStatus.m
//  OBAKit
//
//  Created by Aaron Brethorst on 12/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAOccupancyStatus.h>

OBAOccupancyStatus OBAStringToOccupancyStatus(NSString * stringValue) {
    if ([stringValue isEqualToString:@"empty"]) {
        return OBAOccupancyStatusEmpty;
    }
    else if ([stringValue isEqualToString:@"manySeatsAvailable"]) {
        return OBAOccupancyStatusManySeatsAvailable;
    }
    else if ([stringValue isEqualToString:@"fewSeatsAvailable"]) {
        return OBAOccupancyStatusFewSeatsAvailable;
    }
    else if ([stringValue isEqualToString:@"standingRoomOnly"]) {
        return OBAOccupancyStatusStandingRoomOnly;
    }
    else if ([stringValue isEqualToString:@"crushedStandingRoomOnly"]) {
        return OBAOccupancyStatusCrushedStandingRoomOnly;
    }
    else if ([stringValue isEqualToString:@"full"]) {
        return OBAOccupancyStatusFull;
    }
    else if ([stringValue isEqualToString:@"notAcceptingPassengers"]) {
        return OBAOccupancyStatusNotAcceptingPassengers;
    }
    else {
        return OBAOccupancyStatusUnknown;
    }
}

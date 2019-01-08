//
//  OBAOccupancyStatus.m
//  OBAKit
//
//  Created by Aaron Brethorst on 12/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAOccupancyStatus.h>
#import <OBAKit/OBAMacros.h>

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

NSString * OBALocalizedStringFromOccupancyStatus(OBAOccupancyStatus occupancyStatus) {
    switch (occupancyStatus) {
        case OBAOccupancyStatusEmpty:
            return OBALocalized(@"occupancy_status.empty",);
            break;
        case OBAOccupancyStatusManySeatsAvailable:
            return OBALocalized(@"occupancy_status.many_seats_available",);
            break;
        case OBAOccupancyStatusFewSeatsAvailable:
            return OBALocalized(@"occupancy_status.few_seats_available",);
            break;
        case OBAOccupancyStatusStandingRoomOnly:
            return OBALocalized(@"occupancy_status.standing_room_only",);
            break;
        case OBAOccupancyStatusFull:
            return OBALocalized(@"occupancy_status.full",);
            break;
        case OBAOccupancyStatusNotAcceptingPassengers:
            return OBALocalized(@"occupancy_status.not_accepting_passengers",);
            break;
        default:
            return OBALocalized(@"occupancy_status.unknown",);
    }
}

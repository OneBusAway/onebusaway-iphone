//
//  OBAOccupancyStatus.m
//  OBAKit
//
//  Created by Aaron Brethorst on 12/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAOccupancyStatus.h>

OBAOccupancyStatus OBAStringToOccupancyStatus(NSString * stringValue) {
    if ([stringValue isEqualToString:@"seatsAvailable"]) {
        return OBAOccupancyStatusSeatsAvailable;
    }
    else if ([stringValue isEqualToString:@"standingAvailable"]) {
        return OBAOccupancyStatusStandingAvailable;
    }
    else if ([stringValue isEqualToString:@"full"]) {
        return OBAOccupancyStatusFull;
    }
    else {
        return OBAOccupancyStatusUnknown;
    }
}

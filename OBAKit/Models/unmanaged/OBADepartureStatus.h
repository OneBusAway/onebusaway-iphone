//
//  OBADepartureStatus.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSUInteger, OBADepartureStatus) {
    OBADepartureStatusUnknown = 0,
    OBADepartureStatusEarly,
    OBADepartureStatusOnTime,
    OBADepartureStatusDelayed,
    OBADepartureStatusCanceled
};

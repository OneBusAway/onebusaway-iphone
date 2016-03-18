//
//  OBADepartureCellHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBADepartureCellHelpers.h"

@implementation OBADepartureCellHelpers

+ (NSAttributedString*)attributedDepartureTime:(NSString*)nextDepartureTime statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus {

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:nextDepartureTime attributes:@{NSFontAttributeName: [OBATheme bodyFont]}];

    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@" - "]];

    NSDictionary *attributes = @{NSFontAttributeName: [self fontForStatus:departureStatus], NSForegroundColorAttributeName: [self colorForStatus:departureStatus]};
    NSAttributedString *attributedStatus = [[NSAttributedString alloc] initWithString:statusText attributes:attributes];

    [string appendAttributedString:attributedStatus];

    return string;
}

+ (UIColor*)colorForStatus:(OBADepartureStatus)status {
    if (status == OBADepartureStatusOnTime) {
        return [OBATheme onTimeDepartureColor];
    }
    else if (status == OBADepartureStatusEarly) {
        return [OBATheme earlyDepartureColor];
    }
    else if (status == OBADepartureStatusDelayed) {
        return [OBATheme delayedDepartureColor];
    }
    else {
        return [OBATheme textColor];
    }
}

+ (UIFont*)fontForStatus:(OBADepartureStatus)status {
    return [OBATheme bodyFont];
}

@end

//
//  OBADepartureCellHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBADepartureCellHelpers.h"
#import <DateTools/DateTools.h>

@implementation OBADepartureCellHelpers

+ (NSAttributedString*)attributedDepartureTime:(NSString*)nextDepartureTime statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus prependedText:(nullable NSString*)prependedText {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:prependedText ?: @"" attributes:@{NSFontAttributeName: [OBATheme bodyFont]}];

    [string appendAttributedString:[[NSAttributedString alloc] initWithString:nextDepartureTime attributes:@{NSFontAttributeName: [OBATheme boldBodyFont]}]];

    [string appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@" - ",)]];

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

+ (NSString*)formatDateAsMinutes:(NSDate*)date {
    double minutesFrom = [date minutesFrom:[NSDate date]];

    if (fabs(minutesFrom) < 1.0) {
        return NSLocalizedString(@"NOW", @"");
    }
    else {
        return [NSString stringWithFormat:@"%.0fm", minutesFrom];
    }
}

@end

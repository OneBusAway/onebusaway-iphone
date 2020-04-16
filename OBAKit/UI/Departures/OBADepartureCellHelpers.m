//
//  OBADepartureCellHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBADepartureCellHelpers.h>
#import <OBAKit/OBADateHelpers.h>
#import <OBAKit/OBALogging.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBATheme.h>

@implementation OBADepartureCellHelpers

#pragma mark - Public Methods

// TODO: this method is getting rather grotesque and could use a rethink.
+ (NSAttributedString*)attributedDepartureTimeWithStatusText:(NSString*)statusText upcomingDeparture:(nullable OBAUpcomingDeparture*)upcomingDeparture {

    OBAGuard(statusText.length > 0) else {
        DDLogError(@"departure time should be non-nil and populated.");
        return [[NSAttributedString alloc] init];
    }

    if (!upcomingDeparture) {
        NSDictionary *attributes = @{NSFontAttributeName: [OBATheme subheadFont], NSForegroundColorAttributeName: UIColor.blackColor};
        NSAttributedString *attributedStatus = [[NSAttributedString alloc] initWithString:statusText attributes:attributes];

        return attributedStatus;
    }

    NSString *nextDepartureTime = [OBADateHelpers formatShortTimeNoDate:upcomingDeparture.departureDate];
    OBADepartureStatus departureStatus = upcomingDeparture.departureStatus;

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:nextDepartureTime attributes:@{NSFontAttributeName: [OBATheme subheadFont]}];

    if (upcomingDeparture) {
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:OBALocalized(@" - ",)]];

        NSDictionary *attributes = @{NSFontAttributeName: [self fontForStatus:departureStatus], NSForegroundColorAttributeName: [self colorForStatus:departureStatus]};
        NSAttributedString *attributedStatus = [[NSAttributedString alloc] initWithString:statusText attributes:attributes];

        [string appendAttributedString:attributedStatus];
    }

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
        return [OBATheme scheduledDepartureColor];
    }
}

+ (NSString*)statusTextForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    OBAGuard(arrivalAndDeparture) else {
        return nil;
    }

    if (arrivalAndDeparture.tripStatus.isCanceled) {
        return OBALocalized(@"departure_cell_helpers.trip_canceled", @"Indicates that the trip has been canceled by the agency");
    }

    if (arrivalAndDeparture.frequency) {
        return [self statusStringFromFrequency:arrivalAndDeparture.frequency];
    }

    BOOL pastTense = arrivalAndDeparture.minutesUntilBestDeparture < 0;
    NSInteger minutesDeviation = (NSInteger)fabs(arrivalAndDeparture.predictedDepatureTimeDeviationFromScheduleInMinutes);

    if (arrivalAndDeparture.arrivalDepartureState == OBAArrivalDepartureStateArriving) {
        // Prepended with the word "Arriving"/"Arrived".
        if (arrivalAndDeparture.departureStatus == OBADepartureStatusEarly) {
            NSString *formatString = pastTense ? OBALocalized(@"departure_cell_helpers.arrived_x_minutes_early", @"e.g. 'arrived 3 min early' - note the past tense") :
                                                 OBALocalized(@"departure_cell_helpers.arriving_x_minutes_early", @"e.g. 'arriving 5 min early' - note the future tense");
            return [NSString stringWithFormat:formatString, @(minutesDeviation)];
        }
        else if (arrivalAndDeparture.departureStatus == OBADepartureStatusOnTime) {
            if (pastTense) {
                return OBALocalized(@"departure_cell_helpers.arrived_on_time", @"Indicates that the vehicle arrived on time. Note past tense.");
            }
            else {
                return OBALocalized(@"departure_cell_helpers.arriving_on_time", @"Indicates that the vehicle will arrive on time. Note future tense.");
            }
        }
        else if (arrivalAndDeparture.departureStatus == OBADepartureStatusDelayed) {
            NSString *formatString = pastTense ? OBALocalized(@"departure_cell_helpers.arrived_x_min_late", @"e.g. 'arrived 5 min late'. Note the past tense.") :
                                                 OBALocalized(@"departure_cell_helpers.arriving_x_min_late", @"e.g. 'arriving 4 min late'. Note the future tense.");
            return [NSString stringWithFormat:formatString, @(minutesDeviation)];
        }
        else { /* OBADepartureStatusUnknown */
            return OBALocalized(@"msg_scheduled_arrival_asterisk", @"minutes >= 0");
        }
    }
    else {
        // Prepended with "Departing"/"Departed".

        if (arrivalAndDeparture.departureStatus == OBADepartureStatusEarly) {
            NSString *formatString = pastTense ? OBALocalized(@"departure_cell_helpers.departed_x_min_early", @"e.g. 'departed 1 min early'. Note the past tense.") : OBALocalized(@"departure_cell_helpers.departs_x_min_early", @"e.g. 'departs 1 min early'. Note the future tense.");
            return [NSString stringWithFormat:formatString, @(minutesDeviation)];
        }
        else if (arrivalAndDeparture.departureStatus == OBADepartureStatusOnTime) {
            if (pastTense) {
                return OBALocalized(@"msg_departed_on_time", @"minutes < 0");
            }
            else {
                return OBALocalized(@"msg_on_time", @"minutes >= 0");
            }
        }
        else if (arrivalAndDeparture.departureStatus == OBADepartureStatusDelayed) {
            NSString *formatString = pastTense ? OBALocalized(@"departure_cell_helpers.departed_x_min_late", @"e.g. 'departed 20 min late'. Note the past tense") : OBALocalized(@"departure_cell_helpers.departs_x_min_late", @"e.g. 'departs 12 min late'. Note the future tense");
            return [NSString stringWithFormat:formatString, @(minutesDeviation)];
        }
        else { /* OBADepartureStatusUnknown */
            return OBALocalized(@"msg_scheduled_departure_asterisk", @"minutes < 0");
        }
    }
}

#pragma mark - Private

+ (UIFont*)fontForStatus:(OBADepartureStatus)status {
    return [OBATheme subheadFont];
}

+ (NSString*)statusStringFromFrequency:(OBAFrequencyV2*)frequency {
    NSInteger headway = frequency.headway / 60;

    NSDate *now = [NSDate date];

    NSDate *startTime = [OBADateHelpers dateWithMillisecondsSince1970:frequency.startTime];
    NSDate *endTime = [OBADateHelpers dateWithMillisecondsSince1970:frequency.endTime];

    NSString *formatString = OBALocalized(@"text_frequency_status_params", @"frequency status string");
    NSString *fromOrUntil = [now compare:startTime] == NSOrderedAscending ? OBALocalized(@"msg_from", @"") : OBALocalized(@"msg_until", @"");
    NSDate *terminalDate = [now compare:startTime] == NSOrderedAscending ? startTime : endTime;

    return [NSString stringWithFormat:formatString, @(headway), fromOrUntil, [OBADateHelpers formatShortTimeNoDate:terminalDate]];
}

@end

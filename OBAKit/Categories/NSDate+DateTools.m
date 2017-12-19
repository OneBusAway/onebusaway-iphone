//
//  NSDate+DateTools.m
//  OBAKit
//
//  Created by Aaron Brethorst on 10/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "NSDate+DateTools.h"

#define SECONDS_IN_MINUTE 60.0

@implementation NSDate (DateTools)

- (double)minutesFrom:(NSDate *)date {
    return ([self timeIntervalSinceDate:date])/SECONDS_IN_MINUTE;
}

- (NSUInteger)minutesUntil {
    return (NSUInteger)[self minutesLaterThan:[NSDate date]];
}

/**
 *  Returns the number of minutes the receiver's date is later than the provided comparison date.
 *  Returns 0 if the receiver's date is earlier than or equal to the provided comparison date.
 *
 *  @param date NSDate - Provided date for comparison
 *
 *  @return double representing the number of minutes
 */
- (double)minutesLaterThan:(NSDate *)date {
    return MAX([self minutesFrom:date], 0);
}

- (BOOL)isToday {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:self];
    NSDate *otherDate = [cal dateFromComponents:components];

    return [today isEqualToDate:otherDate];
}

- (BOOL)isTomorrow {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:[[NSDate date] dateByAddingDays:1 withCalendar:cal]];
    NSDate *tomorrow = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:self];
    NSDate *otherDate = [cal dateFromComponents:components];

    return [tomorrow isEqualToDate:otherDate];
}

- (BOOL)isYesterday {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:[[NSDate date] dateBySubtractingDays:1 withCalendar:cal]];
    NSDate *tomorrow = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:self];
    NSDate *otherDate = [cal dateFromComponents:components];
    
    return [tomorrow isEqualToDate:otherDate];
}

/**
 *  Returns a date representing the receivers date shifted later by the provided number of days.
 *
 *  @param days NSInteger - Number of days to add
 *
 *  @return NSDate - Date modified by the number of desired days
 */
- (NSDate *)dateByAddingDays:(NSInteger)days withCalendar:(NSCalendar*)calendar {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:days];

    return [calendar dateByAddingComponents:components toDate:self options:0];
}

/**
 *  Returns a date representing the receivers date shifted earlier by the provided number of days.
 *
 *  @param days NSInteger - Number of days to subtract
 *
 *  @return NSDate - Date modified by the number of desired days
 */
- (NSDate *)dateBySubtractingDays:(NSInteger)days withCalendar:(NSCalendar*)calendar {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:-1*days];

    return [calendar dateByAddingComponents:components toDate:self options:0];
}
@end

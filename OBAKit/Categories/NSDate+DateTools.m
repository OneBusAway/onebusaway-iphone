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

- (double)minutesUntil; {
    return [self minutesLaterThan:[NSDate date]];
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

@end

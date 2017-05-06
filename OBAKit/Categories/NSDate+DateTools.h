//
//  NSDate+DateTools.h
//  OBAKit
//
//  Created by Aaron Brethorst on 10/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;

@interface NSDate (DateTools)

/**
 Returns an NSInteger representing the amount of time in minutes between the receiver and the provided date.
 If the receiver is earlier than the provided date, the returned value will be negative.

 @param date NSDate - The provided date for comparison

 @return The double representation of the minutes between receiver and provided date
 */
- (double)minutesFrom:(NSDate *)date;

/**
 Returns the number of minutes until the receiver's date. Returns 0 if the receiver is the same or earlier than now.

 @return representiation of minutes
 */
- (double)minutesUntil;

- (BOOL)isToday;
- (BOOL)isTomorrow;
- (BOOL)isYesterday;
@end

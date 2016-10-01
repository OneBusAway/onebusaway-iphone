//
//  OBADepartureCellHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OBAKit/OBAKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBADepartureCellHelpers : NSObject

+ (NSAttributedString*)attributedDepartureTime:(NSString*)nextDepartureTime statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus prependedText:(nullable NSString*)prependedText;

+ (UIColor*)colorForStatus:(OBADepartureStatus)status;
+ (UIFont*)fontForStatus:(OBADepartureStatus)status;

+ (NSString*)formatDateAsMinutes:(NSDate*)date;
@end

NS_ASSUME_NONNULL_END

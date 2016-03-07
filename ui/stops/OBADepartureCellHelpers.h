//
//  OBADepartureCellHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OBAKit/OBAKit.h>

@interface OBADepartureCellHelpers : NSObject

+ (NSAttributedString*)attributedDepartureTime:(NSString*)nextDepartureTime statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus;
+ (UIColor*)colorForStatus:(OBADepartureStatus)status;
+ (UIFont*)fontForStatus:(OBADepartureStatus)status;

@end

//
//  OBADepartureTimeLabel.h
//  org.onebusaway.iphone
//
//  Created by Chad Royal on 9/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBADepartureStatus.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBADepartureTimeLabel : UILabel

- (void)setText:(NSString *)minutesUntilDeparture forStatus:(OBADepartureStatus)status;

@end

NS_ASSUME_NONNULL_END

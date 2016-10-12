//
//  OBADepartureTimeLabel.h
//  org.onebusaway.iphone
//
//  Created by Chad Royal on 9/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
@import OBAKit;

@interface OBADepartureTimeLabel : UILabel

-(void)setText:(NSString *)minutesUntilDeparture forStatus:(OBADepartureStatus)status;

@end

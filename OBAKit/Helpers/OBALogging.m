//
//  OBALogging.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/11/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBALogging.h>

const DDLogLevel ddLogLevel = DDLogLevelInfo;

@implementation OBALogging

+ (void)configureLogging {
    [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:ddLogLevel];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:ddLogLevel];
}
@end

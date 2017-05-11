//
//  OBACrashlyticsLogger.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/10/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBACrashlyticsLogger.h"

@implementation OBACrashlyticsLogger

+ (instancetype)sharedInstance {
    static OBACrashlyticsLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[self alloc] init];
    });
    return logger;
}

- (void)logMessage:(DDLogMessage *)logMessage {
    NSString *message = nil;

    if (_logFormatter) {
        message = [_logFormatter formatLogMessage:logMessage];
    }
    else {
        message = logMessage->_message;
    }

    if (message) {
        CLSLog(@"%@", message);
    }
}

@end

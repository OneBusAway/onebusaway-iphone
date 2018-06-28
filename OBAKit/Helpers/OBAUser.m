//
//  OBAUser.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAUser.h>
#import <OBAKit/OBAApplication.h>

static NSString * const kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";

@implementation OBAUser

+ (NSString *)userIDFromDefaults {
    NSString *userId = [OBAApplication.sharedApplication.userDefaults stringForKey:kOBAHiddenPreferenceUserId];

    if (!userId) {
        userId = [[NSUUID UUID] UUIDString];
        [OBAApplication.sharedApplication.userDefaults setObject:userId forKey:kOBAHiddenPreferenceUserId];
    }

    return userId;
}

@end

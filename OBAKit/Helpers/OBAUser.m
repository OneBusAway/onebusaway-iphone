//
//  OBAUser.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAUser.h>

static NSString * const kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";

@implementation OBAUser

+ (NSString *)userIdFromDefaults {
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:kOBAHiddenPreferenceUserId];

    if (!userId) {
        userId = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:userId forKey:kOBAHiddenPreferenceUserId];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    return userId;
}

@end

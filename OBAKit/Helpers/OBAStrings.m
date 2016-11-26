//
//  OBAStrings.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAStrings.h>

@implementation OBAStrings

+ (NSString*)cancel {
    return NSLocalizedString(@"msg_cancel", @"Typically used on alerts and other modal actions. A 'cancel' button.");
}

+ (NSString*)delete {
    return NSLocalizedString(@"msg_delete", @"Typically used on alerts and other modal actions. A 'delete' button.");
}

+ (NSString*)dismiss {
    return NSLocalizedString(@"msg_dismiss", @"Used on alerts. iOS tends to use 'Dismiss' instead of 'OK' on alerts that the user isn't actually agreeing to.");
}

+ (NSString*)edit {
    return NSLocalizedString(@"msg_edit", @"As in 'edit object'.");
}

+ (NSString*)error {
    return NSLocalizedString(@"msg_error", @"The text 'Error'");
}

+ (NSString*)ok {
    return NSLocalizedString(@"msg_ok", @"Standard 'OK' button text.");
}

+ (NSString*)save {
    return NSLocalizedString(@"msg_save", @"Standard 'Save' button text.");
}

+ (NSString*)scheduledDepartureExplanation {
    return NSLocalizedString(@"msg_scheduled_explanatory", @"The explanatory text displayed when a non-realtime trip is displayed on-screen.");
}

@end

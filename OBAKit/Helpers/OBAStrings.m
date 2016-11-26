//
//  OBAStrings.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAStrings.h>
#import <OBAKit/OBAMacros.h>

@implementation OBAStrings

+ (NSString*)cancel {
    return OBALocalized(@"msg_cancel", @"Typically used on alerts and other modal actions. A 'cancel' button.");
}

+ (NSString*)delete {
    return OBALocalized(@"msg_delete", @"Typically used on alerts and other modal actions. A 'delete' button.");
}

+ (NSString*)dismiss {
    return OBALocalized(@"msg_dismiss", @"Used on alerts. iOS tends to use 'Dismiss' instead of 'OK' on alerts that the user isn't actually agreeing to.");
}

+ (NSString*)edit {
    return OBALocalized(@"msg_edit", @"As in 'edit object'.");
}

+ (NSString*)error {
    return OBALocalized(@"msg_error", @"The text 'Error'");
}

+ (NSString*)ok {
    return OBALocalized(@"msg_ok", @"Standard 'OK' button text.");
}

+ (NSString*)save {
    return OBALocalized(@"msg_save", @"Standard 'Save' button text.");
}

+ (NSString*)scheduledDepartureExplanation {
    return OBALocalized(@"msg_scheduled_explanatory", @"The explanatory text displayed when a non-realtime trip is displayed on-screen.");
}

@end

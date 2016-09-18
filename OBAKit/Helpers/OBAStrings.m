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
    return NSLocalizedString(@"Cancel", @"Typically used on alerts and other modal actions. A 'cancel' button.");
}

+ (NSString*)delete {
    return NSLocalizedString(@"Delete", @"Typically used on alerts and other modal actions. A 'delete' button.");
}

+ (NSString*)dismiss {
    return NSLocalizedString(@"Dismiss", @"Used on alerts. iOS tends to use 'Dismiss' instead of 'OK' on alerts that the user isn't actually agreeing to.");
}

+ (NSString*)edit {
    return NSLocalizedString(@"Edit", @"As in 'edit object'.");
}

+ (NSString*)ok {
    return NSLocalizedString(@"OK", @"Standard 'OK' button text.");
}

+ (NSString*)save {
    return NSLocalizedString(@"Save", @"Standard 'Save' button text.");
}

+ (NSString*)scheduledDepartureExplanation {
    return NSLocalizedString(@"*'Scheduled': no vehicle location data available", @"The explanatory text displayed when a non-realtime trip is displayed on-screen.");
}

@end

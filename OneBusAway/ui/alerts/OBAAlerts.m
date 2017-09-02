//
//  OBAAlerts.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/31/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBAAlerts.h"
@import OBAKit;

@implementation OBAAlerts

+ (UIAlertController*)locationServicesDisabledAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_location_services_disabled", @"view.title")
                                                                   message:NSLocalizedString(@"msg_alert_location_services_disabled", @"view.message") preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_fix_it", @"Location services alert button.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        // Appropriate use of -openURL:. Don't replace.
        [UIApplication.sharedApplication openURL:appSettings options:@{} completionHandler:nil];
    }]];

    return alert;
}

@end

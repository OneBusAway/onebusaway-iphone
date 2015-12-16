//
//  OBAAlerts.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/31/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBAAlerts.h"

@implementation OBAAlerts

+ (UIAlertController*)locationServicesDisabledAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Location Services Disabled", @"view.title")
                                                                   message:NSLocalizedString(@"Location Services are disabled for this app. Some location-aware functionality will be missing.", @"view.message") preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"Dismiss button") style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Fix It", @"Location services alert button.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        // Appropriate use of -openURL:. Don't replace.
        [[UIApplication sharedApplication] openURL:appSettings];
    }]];

    return alert;
}

@end

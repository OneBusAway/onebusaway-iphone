//
//  OBAReleaseNotesManager.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/1/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBAReleaseNotesManager.h"
#import "TWSReleaseNotesView.h"

@implementation OBAReleaseNotesManager

+ (BOOL)shouldShowReleaseNotes
{
    BOOL notFirstLaunch =  ![TWSReleaseNotesView isAppOnFirstLaunch];
    BOOL appUpdated = [TWSReleaseNotesView isAppVersionUpdated];
    BOOL isiOS7OrGreater = ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending);

    return (notFirstLaunch && appUpdated && isiOS7OrGreater);
}

+ (void)showReleaseNotes:(UIWindow*)window
{
    [TWSReleaseNotesView setupViewWithAppIdentifier:@"329380089"
                                  releaseNotesTitle:NSLocalizedString(@"What's New", @"")
                                   closeButtonTitle:NSLocalizedString(@"Close", @"")
                                    completionBlock:^(TWSReleaseNotesView *releaseNotesView, NSString *releaseNotesText, NSError *error) {
                                        if (error) {
                                            // Handle errors
                                            NSLog(@"An error occurred: %@", [error localizedDescription]);
                                        }
                                        else {
                                            // Create and show release notes view
                                            [releaseNotesView showInView:window.rootViewController.view];
                                        }
                                    }];
}

@end

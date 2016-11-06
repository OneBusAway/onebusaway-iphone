//
//  OBASettingsViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 11/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBASettingsViewController.h"
@import OBAKit;
#import "OBASwitchRow.h"

@interface OBASettingsViewController ()

@end

@implementation OBASettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Settings", @"title of OBASettingsViewController");

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];

    [self loadData];
}

#pragma mark - Actions

- (void)close {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Data Loading

- (void)loadData {
    OBATableSection *analyticsSection = [[OBATableSection alloc] initWithTitle:nil];

    BOOL analyticsValue = [[NSUserDefaults standardUserDefaults] boolForKey:OBAOptInToTrackingDefaultsKey];
    OBASwitchRow *switchRow = [[OBASwitchRow alloc] initWithTitle:NSLocalizedString(@"Enable Google Analytics", @"A switch option's text for enabling and disabling Google Analytics") action:^{
        [[NSUserDefaults standardUserDefaults] setBool:!analyticsValue forKey:OBAOptInToTrackingDefaultsKey];
    } switchValue:analyticsValue];
    [analyticsSection addRow:switchRow];

    analyticsSection.footerView = [OBAUIBuilder footerViewWithText:NSLocalizedString(@"Some information about how you use this app is sent to Google Analytics in non-personally identifiable form to help us better understand how to improve the app. To learn more, please read our Privacy Policy.", @"Analytics explanation on the Settings view controller.") maximumWidth:CGRectGetWidth(self.tableView.frame)];

    self.sections = @[analyticsSection];
    [self.tableView reloadData];
}

@end

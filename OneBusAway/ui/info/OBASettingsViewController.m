//
//  OBASettingsViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 11/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBASettingsViewController.h"
@import OBAKit;
@import GoogleAnalytics;
#import "OBASwitchRow.h"

@interface OBASettingsViewController ()

@end

@implementation OBASettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"msg_settings", @"title of OBASettingsViewController");

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];

    [self loadData];
}

#pragma mark - Actions

- (void)close {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Data Loading

- (void)loadData {
    NSMutableArray *sections = [[NSMutableArray alloc] init];

    OBATableSection *analyticsSection = [self buildSwitchSectionWithDefaultsKey:OBAOptInToTrackingDefaultsKey switchTitle:NSLocalizedString(@"msg_enable_google_analytics", @"A switch option's text for enabling and disabling Google Analytics") footerText:NSLocalizedString(@"msg_explanatory_google_analytics", @"Analytics explanation on the Settings view controller.")];
    [sections addObject:analyticsSection];

    OBATableSection *crashReportingSection = [self buildSwitchSectionWithDefaultsKey:OBAOptInToCrashReportingDefaultsKey switchTitle:NSLocalizedString(@"settings.crash_reporting.switch_text", @"A switch option's text for enabling and disabling crash reporting") footerText:NSLocalizedString(@"settings.crash_reporting.footer", @"Crash reporting explanation on the Settings view controller.")];
    [sections addObject:crashReportingSection];

    OBATableSection *compassSection = [self buildSwitchSectionWithDefaultsKey:OBADisplayUserHeadingOnMapDefaultsKey switchTitle:NSLocalizedString(@"settings.user_heading_switch_title", @"Title for the enable/disable user heading switch on the settings controller") footerText:NSLocalizedString(@"settings.user_heading_footer_text", @"Footer for the enable/disable user heading switch on the settings controller")];
    [sections addObject:compassSection];

    if ([OBACommon debugMode]) {
        OBATableSection *experimentalSection = [self buildSwitchSectionWithDefaultsKey:OBAExperimentalUseDrawerUIDefaultsKey switchTitle:@"Use Drawer UI" footerText:@"EXPERIMENTAL! Kill app and relaunch to see this in action"];
        [sections addObject:experimentalSection];
    }

    self.sections = sections;
    [self.tableView reloadData];
}

- (OBATableSection*)buildSwitchSectionWithDefaultsKey:(NSString*)defaultsKey switchTitle:(NSString*)switchTitle footerText:(nullable NSString*)footerText  {
    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil];

    OBARowAction action = ^(OBABaseRow *row) {
        BOOL currentValue = [OBAApplication.sharedApplication.userDefaults boolForKey:defaultsKey];
        [OBAApplication.sharedApplication.userDefaults setBool:!currentValue forKey:defaultsKey];
    };

    OBASwitchRow *switchRow = [[OBASwitchRow alloc] initWithTitle:switchTitle action:action switchValue:[OBAApplication.sharedApplication.userDefaults boolForKey:defaultsKey]];
    [section addRow:switchRow];

    if (footerText) {
        section.footerView = [OBAUIBuilder footerViewWithText:footerText maximumWidth:CGRectGetWidth(self.tableView.frame)];
    }

    return section;
}

@end

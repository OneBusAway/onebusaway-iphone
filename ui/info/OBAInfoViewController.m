//
//  OBAInfoViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/17/12.
//
//

#import "OBAInfoViewController.h"
#import "OBAAgenciesListViewController.h"
#import "OBACreditsViewController.h"
#import "OBAAnalytics.h"
#import "OBARegionListViewController.h"
#import <SafariServices/SafariServices.h>
#import <Apptentive/Apptentive.h>
#import <OBAKit/OBAEmailHelper.h>
#import "UILabel+OBAAdditions.h"

static NSString * const kDonateURLString = @"http://onebusaway.org/donate/";
static NSString * const kPrivacyURLString = @"http://onebusaway.org/privacy/";

@interface OBAInfoViewController ()<MFMailComposeViewControllerDelegate>

@end

@implementation OBAInfoViewController

- (id)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Info", @"");
        self.tabBarItem.image = [UIImage imageNamed:@"info"];
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.tableHeaderView = [self buildTableHeaderView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadMessageCountChanged:) name:ApptentiveMessageCenterUnreadCountChangedNotification object:nil];

    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:ApptentiveMessageCenterUnreadCountChangedNotification object:nil];
}

#pragma mark - Notifications

- (void)unreadMessageCountChanged:(NSNotification*)note {
    [self reloadData];
}

#pragma mark - Table Data

- (void)reloadData {
    self.sections = @[
                      [self settingsTableSection],
                      [self contactTableSection],
                      [self aboutTableSection]
                    ];
    [self.tableView reloadData];
}

- (OBATableSection*)settingsTableSection {

    OBATableRow *region = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Region", @"") action:^{
        [self.navigationController pushViewController:[[OBARegionListViewController alloc] init] animated:YES];
    }];
    region.style = UITableViewCellStyleValue1;
    region.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if ([OBAApplication sharedApplication].modelDao.readCustomApiUrl.length == 0) {
        region.subtitle = [OBAApplication sharedApplication].modelDao.region.regionName;
    }
    else {
        region.subtitle = [OBAApplication sharedApplication].modelDao.readCustomApiUrl;
    }

    OBATableRow *agencies = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Agencies", @"Info Page Agencies Row Title") action:^{
        [self openAgencies];
    }];
    agencies.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"Your Location", @"Settings section title on info page") rows:@[region,agencies]];
}

- (OBATableSection*)contactTableSection {

    OBATableRow *contactUs = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Data & Schedule Issues", @"Info Page Contact Us Row Title") action:^{
        [self openContactUs];
    }];
    contactUs.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *reportAppIssue = [OBATableRow tableRowWithTitle:NSLocalizedString(@"App Bugs & Feature Requests", @"A row in the Info tab's table view") action:^{
        [[Apptentive sharedConnection] presentMessageCenterFromViewController:self];
    }];
    reportAppIssue.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSUInteger unreadMessageCount = [[Apptentive sharedConnection] unreadMessageCount];
    if (unreadMessageCount > 0) {
        reportAppIssue.subtitle = [NSString stringWithFormat:NSLocalizedString(@"%@ unread", @"Unread messages count. e.g. 2 unread"), @(unreadMessageCount)];
        reportAppIssue.style = UITableViewCellStyleValue1;
    }

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"Contact Us", @"") rows:@[contactUs, reportAppIssue]];
}

- (OBATableSection*)aboutTableSection {

    OBATableRow *credits = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Credits", @"Info Page Credits Row Title") action:^{
        [self.navigationController pushViewController:[[OBACreditsViewController alloc] init] animated:YES];
    }];
    credits.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *privacy = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Privacy Policy", @"Info Page Privacy Policy Row Title") action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Privacy Policy Link" value:nil];
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:kPrivacyURLString]];
        safari.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentViewController:safari animated:YES completion:nil];
    }];
    privacy.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *donate = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Donate", @"Info Page Donate Row Title") action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Donate Link" value:nil];
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:kDonateURLString]];
        safari.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentViewController:safari animated:YES completion:nil];
    }];
    donate.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"About OneBusAway", @"") rows:@[credits, privacy, donate]];
}

#pragma mark - Email

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self becomeFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cantSendEmail {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please set up your Mail app before trying to send an email.", @"view.message")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"Dismiss button for alert.") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openContactUs {
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Email Link" value:nil];

    MFMailComposeViewController *composer = [OBAEmailHelper mailComposeViewControllerForModelDAO:[OBAApplication sharedApplication].modelDao
                                                                                 currentLocation:[OBAApplication sharedApplication].locationManager.currentLocation];

    if (composer) {
        composer.mailComposeDelegate = self;
        [self presentViewController:composer animated:YES completion:nil];
    }
    else {
        [self cantSendEmail];
    }
}

#pragma mark - Public Methods

- (void)openAgencies {
    [self.navigationController pushViewController:[[OBAAgenciesListViewController alloc] init] animated:YES];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeContactUs];
}

#pragma mark - Private

- (UIView*)buildTableHeaderView {
    UIView *header = [[UIView alloc] initWithFrame:self.view.bounds];
    header.backgroundColor = OBAGREEN;

    CGRect frame = header.frame;
    frame.size.height = 160.f;
    header.frame = frame;

    CGFloat verticalPadding = 8.f;

    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, verticalPadding, CGRectGetWidth(header.frame), 100)];
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    iconImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    iconImageView.image = [UIImage imageNamed:@"infoheader"];
    [header addSubview:iconImageView];

    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(iconImageView.frame), CGRectGetWidth(header.frame), 30.f)];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    headerLabel.text = NSLocalizedString(@"OneBusAway", @"");
    headerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [headerLabel oba_resizeHeightToFit];
    [header addSubview:headerLabel];

    UILabel *copyrightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(headerLabel.frame), CGRectGetWidth(header.frame), 30.f)];
    copyrightLabel.textAlignment = NSTextAlignmentCenter;
    copyrightLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    copyrightLabel.text = [NSString stringWithFormat:@"%@\r\n%@", [OBAApplication sharedApplication].fullAppVersionString, @"© University of Washington"];
    copyrightLabel.numberOfLines = 2;
    copyrightLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [copyrightLabel oba_resizeHeightToFit];
    [header addSubview:copyrightLabel];

    frame.size.height = CGRectGetMaxY(copyrightLabel.frame) + verticalPadding;
    header.frame = frame;

    return header;
}

@end

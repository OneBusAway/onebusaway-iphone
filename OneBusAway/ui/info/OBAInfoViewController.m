//
//  OBAInfoViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/17/12.
//
//

#import "OBAInfoViewController.h"
@import SafariServices;
@import Masonry;
@import MobileCoreServices;
@import OBAKit;
#import "OBAAgenciesListViewController.h"
#import "OBASettingsViewController.h"
#import "OBACreditsViewController.h"
#import "OBAAnalytics.h"
#import "OneBusAway-Swift.h"
#import "OBAPushManager.h"

static NSString * const kRepoURLString = @"https://www.github.com/onebusaway/onebusaway-iphone";
static NSString * const kPrivacyURLString = @"http://onebusaway.org/privacy/";

@interface OBAInfoViewController ()<MFMailComposeViewControllerDelegate>
@property(nonatomic,strong) UITapGestureRecognizer *debugTapRecognizer;
@end

@implementation OBAInfoViewController

- (id)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"msg_info", @"");
        self.tabBarItem.image = [UIImage imageNamed:@"Info"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"Info_Selected"];
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"msg_settings", @"Settings bar button item title on the info view controller.") style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];

    UIView *header = [self buildTableHeaderView];
    [self setTableViewHeader:header];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    OBALogFunction();

    [self reloadData];
}

#pragma mark - Notifications

- (void)unreadMessageCountChanged:(NSNotification*)note {
    [self reloadData];
}

#pragma mark - Lazy Loading

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (OBALocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager = [OBAApplication sharedApplication].locationManager;
    }
    return _locationManager;
}

#pragma mark - Debug Mode

- (UITapGestureRecognizer*)debugTapRecognizer {
    if (!_debugTapRecognizer) {
        _debugTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleDebugMode:)];
        _debugTapRecognizer.numberOfTapsRequired = 5;
    }
    return _debugTapRecognizer;
}

- (void)toggleDebugMode:(UITapGestureRecognizer*)sender {
    BOOL debugMode = [[NSUserDefaults standardUserDefaults] boolForKey:OBADebugModeUserDefaultsKey];
    debugMode = !debugMode;
    [[NSUserDefaults standardUserDefaults] setBool:debugMode forKey:OBADebugModeUserDefaultsKey];

    NSString *message = debugMode ? NSLocalizedString(@"info_controller.debug_mode_enabled", @"Message shown when debug mode is turned on") : NSLocalizedString(@"info_controller.debug_mode_disabled", @"Message shown when debug mode is turned off");

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.ok style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:^{
        [self reloadData];
    }];
}

#pragma mark - Table Data

- (void)reloadData {

    NSMutableArray *sections = [[NSMutableArray alloc] init];

    if ([OBACommon debugMode]) {
        [sections addObject:[self debugTableSection]];
    }

    // Only show the alerts section if this region supports it.
    if ([OBAApplication sharedApplication].regionalAlertsManager.regionalAlerts.count > 0) {
        [sections addObject:[self alertsTableSection]];
    }

    [sections addObjectsFromArray:@[[self settingsTableSection],
                                    [self contactTableSection],
                                    [self aboutTableSection]]];

    self.sections = sections;
    [self.tableView reloadData];
}

- (OBATableSection*)alertsTableSection {
    NSString *rowTitle = [NSString stringWithFormat:NSLocalizedString(@"info_controller.updates_alerts_row_format", @"Title for Updates & Alerts row. e.g. Alerts for <Region Name>"), self.modelDAO.currentRegion.regionName];
    OBATableRow *row = [[OBATableRow alloc] initWithTitle:rowTitle action:^(OBABaseRow *r2) {
        RegionalAlertsViewController *alertsController = [[RegionalAlertsViewController alloc] initWithRegionalAlertsManager:[OBAApplication sharedApplication].regionalAlertsManager];
        [self.navigationController pushViewController:alertsController animated:YES];
    }];
    NSUInteger unreadCount = [OBAApplication sharedApplication].regionalAlertsManager.unreadCount;

    if (unreadCount > 0) {
        row.subtitle = [NSString stringWithFormat:@"%@", @(unreadCount)];
    }
    row.style = UITableViewCellStyleValue1;
    row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"info_controller.updates_alerts_section_title", @"Title for the Updates & Alerts section") rows:@[row]];
}

- (OBATableSection*)settingsTableSection {

    OBATableRow *region = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_region", @"") action:^(OBABaseRow *r2) {
        [self.navigationController pushViewController:[[RegionListViewController alloc] init] animated:YES];
    }];
    region.style = UITableViewCellStyleValue1;
    region.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    region.subtitle = self.modelDAO.currentRegion.regionName;

    OBATableRow *agencies = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_agencies", @"Info Page Agencies Row Title") action:^(OBABaseRow *r2) {
        [self openAgencies];
    }];
    agencies.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"msg_your_location", @"Settings section title on info page") rows:@[region,agencies]];
}

- (OBATableSection*)contactTableSection {
    NSMutableArray *rows = [[NSMutableArray alloc] init];

    OBATableRow *contactTransitAgency = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_data_schedule_issues", @"Info Page Contact Us Row Title") action:^(OBABaseRow *r2) {
        [self contactTransitAgency];
    }];
    contactTransitAgency.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [rows addObject:contactTransitAgency];

    OBATableRow *contactAppDevelopers = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"info_controller.contact_app_developers_row_title", @"'Contact app developers about a bug' row") action:^(OBABaseRow *r2) {
        [self contactAppDevelopers];
    }];
    contactAppDevelopers.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [rows addObject:contactAppDevelopers];

    OBATableSection *section = [OBATableSection tableSectionWithTitle:NSLocalizedString(@"msg_contact_us", @"") rows:rows];

    return section;
}

- (OBATableSection*)aboutTableSection {
    OBATableRow *credits = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_credits", @"Info Page Credits Row Title") action:^(OBABaseRow *r2) {
        [self.navigationController pushViewController:[[OBACreditsViewController alloc] init] animated:YES];
    }];
    credits.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *privacy = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_privacy_policy", @"Info Page Privacy Policy Row Title") action:^(OBABaseRow *r2) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Privacy Policy Link" value:nil];
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:kPrivacyURLString]];
        safari.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentViewController:safari animated:YES completion:nil];
    }];
    privacy.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"msg_about_oba", @"") rows:@[credits, privacy]];
}

- (OBATableSection*)debugTableSection {
    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"info_controller.debug_section_title", @"The table section title for the debugging tools.")];

    OBATableRow *row = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"info_controller.browse_user_defaults_row", @"Row title for the Browse User Defaults action") action:^(OBABaseRow *r2) {
        UserDefaultsBrowserViewController *browser = [[UserDefaultsBrowserViewController alloc] init];
        [self.navigationController pushViewController:browser animated:YES];
    }];
    row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [section addRow:row];

    return section;
}

#pragma mark - Email

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self becomeFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cantSendEmail:(OBAEmailTarget)target {
    NSString *emailAddress = [[self buildEmailHelper] emailAddressForTarget:target];
    NSString *title = NSLocalizedString(@"info.email_app_not_set_up_title", @"Title of the the alert that appears when you try sending an email without Mail.app set up");
    NSString *bodyFormat = NSLocalizedString(@"info.email_app_not_set_up_body_format", @"Body of the the alert that appears when you try sending an email without Mail.app set up");

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:[NSString stringWithFormat:bodyFormat, emailAddress]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"info.email_app_copy_email_address", @"Button that copies the targeted email address to the user's clipboard") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIPasteboard.generalPasteboard.string = [[self buildEmailHelper] emailAddressForTarget:target];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"info.email_app_copy_debug_info", @"Button that copies debug info to the user's clipboard") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBAEmailHelper *helper = [self buildEmailHelper];
        UIPasteboard.generalPasteboard.string = helper.messageBodyText;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleDefault handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)contactTransitAgency {
    [self presentEmailComposerForTarget:OBAEmailTargetTransitAgency];
}

- (void)contactAppDevelopers {
    [self presentEmailComposerForTarget:OBAEmailTargetAppDevelopers];
}

- (OBAEmailHelper*)buildEmailHelper {
    CLLocation *currentLocation = [OBAApplication sharedApplication].locationManager.currentLocation;
    return [[OBAEmailHelper alloc] initWithModelDAO:self.modelDAO currentLocation:currentLocation registeredForRemoteNotifications:UIApplication.sharedApplication.registeredForRemoteNotifications locationAuthorizationStatus:self.locationManager.authorizationStatus];
}

- (void)presentEmailComposerForTarget:(OBAEmailTarget)emailTarget {
    OBAEmailHelper *emailHelper = [self buildEmailHelper];

    MFMailComposeViewController *composer = [emailHelper mailComposerForEmailTarget:emailTarget];

    if (composer) {
        composer.mailComposeDelegate = self;
        [self presentViewController:composer animated:YES completion:nil];
    }
    else {
        [self cantSendEmail:emailTarget];
    }
}

#pragma mark - Public Methods

- (void)openAgencies {
    [self.navigationController pushViewController:[[OBAAgenciesListViewController alloc] init] animated:YES];
}

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget navigationTarget:OBANavigationTargetTypeContactUs];
}

- (void)setNavigationTarget:(OBANavigationTarget *)navigationTarget {
    if (navigationTarget.searchType == OBASearchTypeRegionalAlert) {
        RegionalAlertsViewController *alertsController = [[RegionalAlertsViewController alloc] initWithRegionalAlertsManager:[OBAApplication sharedApplication].regionalAlertsManager focusedAlert:navigationTarget.searchArgument];
        [self.navigationController pushViewController:alertsController animated:YES];
    }
}

#pragma mark - Private

- (void)showSettings {
    OBASettingsViewController *settings = [[OBASettingsViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];

    [self presentViewController:navigation animated:YES completion:nil];
}

- (void)openGitHub {
    NSURL *URL = [NSURL URLWithString:kRepoURLString];
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:URL];
    safari.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:safari animated:YES completion:nil];
}

+ (UILabel*)centeredLabelWithText:(NSString*)text font:(UIFont*)font {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.font = font;
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    return label;
}

- (UIView*)buildTableHeaderView {
    UIView *header = [[UIView alloc] initWithFrame:CGRectZero];
    header.backgroundColor = [OBATheme OBAGreen];

    NSMutableArray<UIView*> *views = [[NSMutableArray alloc] init];

    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"infoheader"]];
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [iconImageView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [iconImageView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [iconImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [iconImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [iconImageView addGestureRecognizer:self.debugTapRecognizer];
    iconImageView.userInteractionEnabled = YES;
    [views addObject:iconImageView];

    UIFont *headlineFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    UIFont *subHeadlineFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

    UILabel *headerLabel = [self.class centeredLabelWithText:NSLocalizedString(@"msg_oba_name",) font:headlineFont];
    [headerLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [views addObject:headerLabel];

    UILabel *copyrightLabel = [self.class centeredLabelWithText:[NSString stringWithFormat:@"%@\r\n%@", [OBAApplication sharedApplication].fullAppVersionString, @"© University of Washington"] font:subHeadlineFont];
    [copyrightLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [views addObject:copyrightLabel];

    UILabel *volunteerLabel = [self.class centeredLabelWithText:NSLocalizedString(@"msg_onebusaway_made_by_volunteers",) font:subHeadlineFont];
    [volunteerLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [views addObject:volunteerLabel];

    BorderedButton *volunteerButton = [[BorderedButton alloc] initWithBorderColor:[UIColor blackColor] title:NSLocalizedString(@"msg_visit_us",)];
    [volunteerButton addTarget:self action:@selector(openGitHub) forControlEvents:UIControlEventTouchUpInside];
    [volunteerButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [volunteerButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [volunteerButton setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [volunteerButton setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [views addObject:volunteerButton];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:views];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = [OBATheme defaultPadding];
    stack.distribution = UIStackViewDistributionFill;
    stack.alignment = UIStackViewAlignmentFill;

    [header addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(header).insets([OBATheme defaultEdgeInsets]);
    }];

    return header;
}

/*
 This whole song and dance routine with the table header
 is necessary because table headers don't play very well
 with auto layout. In order to make the header work,
 we need to install it, calculate the height, set the
 height and then reinstall it. Ugh.
 */
- (void)setTableViewHeader:(UIView*)header {
    self.tableView.tableHeaderView = header;
    [header setNeedsLayout];
    [header layoutIfNeeded];
    CGFloat height = [header systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

    CGRect headerFrame = header.frame;
    headerFrame.size.height = height;
    header.frame = headerFrame;
    self.tableView.tableHeaderView = header;
}

@end

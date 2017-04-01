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

#import "OBAAgenciesListViewController.h"
#import "OBASettingsViewController.h"
#import "OBACreditsViewController.h"
#import "OBAAnalytics.h"
#import "Apptentive.h"
#import "OneBusAway-Swift.h"

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

#pragma mark - Lazy Loading

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (PrivacyBroker*)privacyBroker {
    if (!_privacyBroker) {
        _privacyBroker = [OBAApplication sharedApplication].privacyBroker;
    }
    return _privacyBroker;
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
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table Data

- (void)reloadData {
    self.sections = @[
                      [self settingsTableSection],
                      [self contactTableSection],
                      [self privacyTableSection],
                      [self aboutTableSection]
                    ];
    [self.tableView reloadData];
}

- (OBATableSection*)settingsTableSection {

    OBATableRow *region = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_region", @"") action:^{
        [self.navigationController pushViewController:[[RegionListViewController alloc] init] animated:YES];
    }];
    region.style = UITableViewCellStyleValue1;
    region.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    region.subtitle = self.modelDAO.currentRegion.regionName;

    OBATableRow *agencies = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_agencies", @"Info Page Agencies Row Title") action:^{
        [self openAgencies];
    }];
    agencies.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"msg_your_location", @"Settings section title on info page") rows:@[region,agencies]];
}

- (OBATableSection*)contactTableSection {
    NSMutableArray *rows = [[NSMutableArray alloc] init];

    OBATableRow *contactUs = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_data_schedule_issues", @"Info Page Contact Us Row Title") action:^{
        [self openContactUs];
    }];
    contactUs.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [rows addObject:contactUs];
    
    if ([Apptentive sharedConnection].canShowMessageCenter) {
      OBATableRow *reportAppIssue = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_app_bugs_feature_requests",) action:^{
          [self presentApptentiveMessageCenter];
      }];
      reportAppIssue.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      if ([Apptentive sharedConnection].unreadMessageCount > 0) {
          reportAppIssue.accessoryView = [[Apptentive sharedConnection] unreadMessageCountAccessoryView:YES];
      }
      
      [rows addObject:reportAppIssue];
    }

    OBATableRow *logs = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_send_logs",) action:^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_ask_send_logs",) message:NSLocalizedString(@"msg_explanatory_send_log_data",) preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_send",) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            for (NSData *logData in self.privacyBroker.shareableLogData) {
                [[Apptentive sharedConnection] sendAttachmentFile:logData withMimeType:@"text/plain"];
            }

            [AlertPresenter showSuccess:NSLocalizedString(@"msg_log_files_sent",) body:NSLocalizedString(@"msg_thank_you_exclamation",)];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    [rows addObject:logs];

    OBATableSection *section = [OBATableSection tableSectionWithTitle:NSLocalizedString(@"msg_contact_us", @"") rows:rows];

    return section;
}

- (OBATableSection*)privacyTableSection {
    OBATableRow *privacy = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_privacy_policy", @"Info Page Privacy Policy Row Title") action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Privacy Policy Link" value:nil];
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:kPrivacyURLString]];
        safari.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentViewController:safari animated:YES completion:nil];
    }];
    privacy.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *PII = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_information_for_support",) action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Opened PII controller" value:nil];
        PIIViewController *PIIController = [[PIIViewController alloc] init];
        [self.navigationController pushViewController:PIIController animated:YES];
    }];
    PII.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_privacy",) rows:@[privacy, PII]];

    return section;
}

- (OBATableSection*)aboutTableSection {

    OBATableRow *credits = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_credits", @"Info Page Credits Row Title") action:^{
        [self.navigationController pushViewController:[[OBACreditsViewController alloc] init] animated:YES];
    }];
    credits.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"msg_about_oba", @"") rows:@[credits]];
}

#pragma mark - Email

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self becomeFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cantSendEmail {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_set_up_mail_to_send_email", @"view.message")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openContactUs {
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Email Link" value:nil];

    MFMailComposeViewController *composer = [OBAEmailHelper mailComposeViewControllerForModelDAO:self.modelDAO
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

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget navigationTarget:OBANavigationTargetTypeContactUs];
}

#pragma mark - Private

- (void)showSettings {
    OBASettingsViewController *settings = [[OBASettingsViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];

    [self presentViewController:navigation animated:YES completion:nil];
}

- (void)presentApptentiveMessageCenter {
    // Information that cannot be used to uniquely identify the user is shared automatically.
    [[Apptentive sharedConnection] addCustomPersonDataBool:self.modelDAO.automaticallySelectRegion withKey:@"Automatically Select Region"];
    [[Apptentive sharedConnection] addCustomPersonDataBool:(!!self.modelDAO.currentRegion) withKey:@"Region Selected"];
    [[Apptentive sharedConnection] addCustomPersonDataString:locationAuthorizationStatusToString(self.locationManager.authorizationStatus) withKey:@"Location Auth Status"];

    // Information that can be used to uniquely identify the user is not shared automatically.

    if (self.privacyBroker.shareableLocationInformation) {
        [[Apptentive sharedConnection] addCustomPersonDataString:self.privacyBroker.shareableLocationInformation withKey:@"Location"];
    }
    else {
        [[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"Location"];
    }

    NSDictionary *regionInfo = self.privacyBroker.shareableRegionInformation;
    for (NSString *key in regionInfo) {
        if (self.privacyBroker.canShareRegionInformation) {
            [[Apptentive sharedConnection] addCustomPersonDataString:regionInfo[key] withKey:key];
        }
        else {
            [[Apptentive sharedConnection] removeCustomPersonDataWithKey:key];
        }
    }

    [[Apptentive sharedConnection] presentMessageCenterFromViewController:self];
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

    UIButton *volunteerButton = [OBAUIBuilder borderedButtonWithTitle:NSLocalizedString(@"msg_visit_us",)];
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

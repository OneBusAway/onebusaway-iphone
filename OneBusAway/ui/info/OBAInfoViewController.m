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

@end

@implementation OBAInfoViewController

- (id)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Info", @"");
        self.tabBarItem.image = [UIImage imageNamed:@"Info"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"Info_Selected"];
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", @"Settings bar button item title on the info view controller.") style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];

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

    OBATableRow *region = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Region", @"") action:^{
        [self.navigationController pushViewController:[[RegionListViewController alloc] init] animated:YES];
    }];
    region.style = UITableViewCellStyleValue1;
    region.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    region.subtitle = self.modelDAO.currentRegion.regionName;

    OBATableRow *agencies = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Agencies", @"Info Page Agencies Row Title") action:^{
        [self openAgencies];
    }];
    agencies.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"Your Location", @"Settings section title on info page") rows:@[region,agencies]];
}

- (OBATableSection*)contactTableSection {
    NSMutableArray *rows = [[NSMutableArray alloc] init];

    OBATableRow *contactUs = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Data & Schedule Issues", @"Info Page Contact Us Row Title") action:^{
        [self openContactUs];
    }];
    contactUs.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [rows addObject:contactUs];
    
    if ([Apptentive sharedConnection].canShowMessageCenter) {
      OBATableRow *reportAppIssue = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"App Bugs & Feature Requests",) action:^{
          [self presentApptentiveMessageCenter];
      }];
      reportAppIssue.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      if ([Apptentive sharedConnection].unreadMessageCount > 0) {
          reportAppIssue.accessoryView = [[Apptentive sharedConnection] unreadMessageCountAccessoryView:YES];
      }
      
      [rows addObject:reportAppIssue];
    }

    OBATableRow *logs = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Send Logs to Support",) action:^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Send Logs to Support?",) message:NSLocalizedString(@"This will send your log data to app support. This may be necessary to help diagnose bugs. Check the \"Information for Support\" section to see what your logs contain.",) preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send",) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            for (NSData *logData in self.privacyBroker.shareableLogData) {
                [[Apptentive sharedConnection] sendAttachmentFile:logData withMimeType:@"text/plain"];
            }

            [AlertPresenter showSuccess:NSLocalizedString(@"Log Files Sent",) body:NSLocalizedString(@"Thank you!",)];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    [rows addObject:logs];

    OBATableSection *section = [OBATableSection tableSectionWithTitle:NSLocalizedString(@"Contact Us", @"") rows:rows];

    return section;
}

- (OBATableSection*)privacyTableSection {
    OBATableRow *privacy = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Privacy Policy", @"Info Page Privacy Policy Row Title") action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Privacy Policy Link" value:nil];
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:kPrivacyURLString]];
        safari.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentViewController:safari animated:YES completion:nil];
    }];
    privacy.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *PII = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Information for Support",) action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Opened PII controller" value:nil];
        PIIViewController *PIIController = [[PIIViewController alloc] init];
        [self.navigationController pushViewController:PIIController animated:YES];
    }];
    PII.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Privacy",) rows:@[privacy, PII]];

    return section;
}

- (OBATableSection*)aboutTableSection {

    OBATableRow *credits = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Credits", @"Info Page Credits Row Title") action:^{
        [self.navigationController pushViewController:[[OBACreditsViewController alloc] init] animated:YES];
    }];
    credits.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"About OneBusAway", @"") rows:@[credits]];
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
    [views addObject:iconImageView];

    UIFont *headlineFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    UIFont *subHeadlineFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

    UILabel *headerLabel = [self.class centeredLabelWithText:NSLocalizedString(@"OneBusAway",) font:headlineFont];
    [headerLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [views addObject:headerLabel];

    UILabel *copyrightLabel = [self.class centeredLabelWithText:[NSString stringWithFormat:@"%@\r\n%@", [OBAApplication sharedApplication].fullAppVersionString, @"© University of Washington"] font:subHeadlineFont];
    [copyrightLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [views addObject:copyrightLabel];

    UILabel *volunteerLabel = [self.class centeredLabelWithText:NSLocalizedString(@"OneBusAway for iOS is made and supported by volunteers. To help, tap the button below.",) font:subHeadlineFont];
    [volunteerLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [views addObject:volunteerLabel];

    UIButton *volunteerButton = [OBAUIBuilder borderedButtonWithTitle:NSLocalizedString(@"Visit Us",)];
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

//
//  OBAInfoViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/17/12.
//
//

#import "OBAInfoViewController.h"
#import "OBAContactUsViewController.h"
#import "OBAAgenciesListViewController.h"
#import "OBACreditsViewController.h"
#import "OBAAnalytics.h"
#import "OBARegionListViewController.h"
#import "OBAApplicationDelegate.h"

static NSString * const kDonateURLString = @"http://onebusaway.org/donate/";
static NSString * const kPrivacyURLString = @"http://onebusaway.org/privacy/";
static NSString * const kFeatureRequestsURLString = @"http://onebusaway.ideascale.com/a/ideafactory.do?id=8715&mode=top&discussionFilter=byids&discussionID=46166";

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

    [self reloadData];
}

#pragma mark - Table Data

- (void)reloadData {
    self.sections = @[
                      [self settingsTableSection],
                      [self aboutTableSection]
                    ];
    [self.tableView reloadData];
}

- (OBATableSection*)settingsTableSection {

    OBATableRow *region = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Region", @"") action:^{
        [self.navigationController pushViewController:[[OBARegionListViewController alloc] initWithApplicationDelegate:self.appDelegate] animated:YES];
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

- (OBATableSection*)aboutTableSection {

#if 0
    OBATableRow *featureRequests = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Feature Requests", @"Info Page Feature Requests Row Title") action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Feature Request Link" value:nil];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kFeatureRequestsURLString]];
    }];
#endif

    OBATableRow *contactUs = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Contact Us", @"Info Page Contact Us Row Title") action:^{
        [self openContactUs];
    }];
    contactUs.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *credits = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Credits", @"Info Page Credits Row Title") action:^{
        [self.navigationController pushViewController:[[OBACreditsViewController alloc] init] animated:YES];
    }];
    credits.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *privacy = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Privacy Policy", @"Info Page Privacy Policy Row Title") action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Privacy Policy Link" value:nil];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kPrivacyURLString]];
    }];
    privacy.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *donate = [OBATableRow tableRowWithTitle:NSLocalizedString(@"Donate", @"Info Page Donate Row Title") action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Donate Link" value:nil];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kDonateURLString]];
    }];
    donate.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return [OBATableSection tableSectionWithTitle:NSLocalizedString(@"About OneBusAway", @"") rows:@[contactUs, credits, privacy, donate]];
}

#pragma mark - Public Methods

- (void)openContactUs {
    [self.navigationController pushViewController:[[OBAContactUsViewController alloc] init] animated:YES];
}

- (void)openAgencies {
    [self.navigationController pushViewController:[[OBAAgenciesListViewController alloc] init] animated:YES];
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
    [self.class resizeLabelHeightToFitText:headerLabel];
    [header addSubview:headerLabel];

    UILabel *copyrightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(headerLabel.frame), CGRectGetWidth(header.frame), 30.f)];
    copyrightLabel.textAlignment = NSTextAlignmentCenter;
    copyrightLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    copyrightLabel.text = [NSString stringWithFormat:@"%@\r\n%@", [OBAApplication sharedApplication].fullAppVersionString, @"© University of Washington"];
    copyrightLabel.numberOfLines = 2;
    copyrightLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [self.class resizeLabelHeightToFitText:copyrightLabel];
    [header addSubview:copyrightLabel];

    frame.size.height = CGRectGetMaxY(copyrightLabel.frame) + verticalPadding;
    header.frame = frame;

    return header;
}

// TODO: move me into a category or something.
+ (CGRect)resizeLabelHeightToFitText:(UILabel*)label {
    CGRect calculatedRect = [label.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(label.frame), CGFLOAT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName: label.font}
                                                     context:nil];

    CGRect labelFrame = label.frame;
    labelFrame.size.height = CGRectGetHeight(calculatedRect);
    label.frame = labelFrame;

    return label.frame;
}
@end

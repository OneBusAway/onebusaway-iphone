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
#import "OBASettingsViewController.h"
#import "OBACreditsViewController.h"
#import "OBAAnalytics.h"

#define kSettingsRow 0
#define kAgenciesRow 1
#define kFeatureRequests 2
#define kContactUsRow 3
#define kCreditsRow 4
#define kPrivacy 5

#define kRowCount 6

@implementation OBAInfoViewController

- (id)init {
    self = [super initWithNibName:@"OBAInfoViewController" bundle:nil];
    if (self) {
        self.title = NSLocalizedString(@"Info", @"");
        self.tabBarItem.image = [UIImage imageNamed:@"info"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    footerView.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:footerView];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.frame = self.view.bounds;
}

- (void) openContactUs {
    UIViewController *pushMe = nil;
    pushMe = [[OBAContactUsViewController alloc] init];
    [self.navigationController pushViewController:pushMe animated:YES];
}

- (void) openSettings {
    UIViewController *pushMe = nil;
    pushMe = [[OBASettingsViewController alloc] init];
    [self.navigationController pushViewController:pushMe animated:YES];
}

- (void) openAgencies {
    UIViewController *pushMe = nil;
    pushMe = [[OBAAgenciesListViewController alloc] init];
    [self.navigationController pushViewController:pushMe animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kRowCount;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:19];
    }

    switch (indexPath.row) {
        case kContactUsRow: {
            cell.textLabel.text = NSLocalizedString(@"Contact Us", @"info row contact us");
            break;
        }
        case kSettingsRow: {
            cell.textLabel.text = NSLocalizedString(@"Settings", @"info row settings");
            break;
        }
        case kAgenciesRow: {
            cell.textLabel.text = NSLocalizedString(@"Agencies", @"info row agencies");
            break;
        }
        case kCreditsRow: {
            cell.textLabel.text = NSLocalizedString(@"Credits", @"info row credits");
            break;
        }
        case kFeatureRequests: {
            cell.textLabel.text = NSLocalizedString(@"Feature Requests", @"info row feture requests");
            break;
        }
        case kPrivacy: {
            cell.textLabel.text = NSLocalizedString(@"Privacy Policy", @"info row privacy");
            break;
        }
        default:
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UIViewController *pushMe = nil;

    switch (indexPath.row) {
        case kContactUsRow: {
            [self openContactUs];
            break;
        }
        case kSettingsRow: {
            [self openSettings];
            break;
        }
        case kAgenciesRow: {
            [self openAgencies];
            break;
        }
        case kCreditsRow: {
            pushMe = [[OBACreditsViewController alloc] init];
            [self.navigationController pushViewController:pushMe animated:YES];
            break;
        }
        case kFeatureRequests: {
            [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Feature Request Link" value:nil];
            NSString *url = [NSString stringWithString: NSLocalizedString(@"http://onebusaway.ideascale.com/a/ideafactory.do?id=8715&mode=top&discussionFilter=byids&discussionID=46166",@"didSelectRowAtIndexPath case 1")];
            [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
            break;
        }
        case kPrivacy: {
            [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked Privacy Policy Link" value:nil];
            NSString *url = [NSString stringWithString: NSLocalizedString(@"http://onebusaway.org/privacy/",@"didSelectRowAtIndexPath case 3")];
            [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
            break;
        }
        default:
            break;
    }
}

@end

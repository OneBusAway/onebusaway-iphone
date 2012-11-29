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
#import "IASKAppSettingsViewController.h"
#import "OBACreditsViewController.h"

#define kContactUsRow 0
#define kSettingsRow 1
#define kAgenciesRow 2
#define kCreditsRow 3

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
    
    self.tableView.tableHeaderView = self.headerView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    switch (indexPath.row) {
        case kContactUsRow: {
            cell.textLabel.text = NSLocalizedString(@"Contact Us", @"");
            break;
        }
        case kSettingsRow: {
            cell.textLabel.text = NSLocalizedString(@"Settings", @"");
            break;
        }
        case kAgenciesRow: {
            cell.textLabel.text = NSLocalizedString(@"Agencies", @"");
            break;
        }
        case kCreditsRow: {
            cell.textLabel.text = NSLocalizedString(@"Credits", @"");
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
            pushMe = [[OBAContactUsViewController alloc] init];
            break;
        }
        case kSettingsRow: {
            pushMe = [[IASKAppSettingsViewController alloc] init];
            pushMe.title = NSLocalizedString(@"Settings", @"");
            ((IASKAppSettingsViewController*)pushMe).delegate = APP_DELEGATE;

            break;
        }
        case kAgenciesRow: {
            pushMe = [[OBAAgenciesListViewController alloc] init];
            break;
        }
        case kCreditsRow: {
            pushMe = [[OBACreditsViewController alloc] init];
            break;
        }
        default:
            break;
    }

    [self.navigationController pushViewController:pushMe animated:YES];
}

@end

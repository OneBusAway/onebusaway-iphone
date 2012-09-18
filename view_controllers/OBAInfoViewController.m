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

@implementation OBAInfoViewController

- (id)init {
    self = [super initWithNibName:@"OBAInfoViewController" bundle:nil];

    if (self) {
        //
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

    if (0 == indexPath.row) {
        cell.textLabel.text = NSLocalizedString(@"Contact Us", @"");
    }
    else if (1 == indexPath.row) {
        cell.textLabel.text = NSLocalizedString(@"Settings", @"");
    }
    else if (2 == indexPath.row) {
        cell.textLabel.text = NSLocalizedString(@"Agencies", @"");
    }
    else {
        cell.textLabel.text = NSLocalizedString(@"Credits", @"");
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIViewController *pushMe = nil;
    if (0 == indexPath.row) {
        // Contact Us
        pushMe = [[OBAContactUsViewController alloc] init];
    }
    else if (1 == indexPath.row) {
        // Settings
        pushMe = [[IASKAppSettingsViewController alloc] init];
        pushMe.title = NSLocalizedString(@"Settings", @"");
        // TODO: Bring this out of the app context.
        //settingsViewController.delegate = self;
    }
    else if (2 == indexPath.row) {
        // Agencies
         pushMe = [[OBAAgenciesListViewController alloc] init];
    }
    else {
        // Credits
        pushMe = [[OBACreditsViewController alloc] init];
    }
    [self.navigationController pushViewController:pushMe animated:YES];
}

@end

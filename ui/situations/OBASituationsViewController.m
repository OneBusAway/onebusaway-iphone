//
//  OBASituationsViewController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 11/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OBASituationsViewController.h"
#import "OBASituationV2.h"
#import "OBASituationViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"


@implementation OBASituationsViewController

#pragma mark - Initialization

+ (void)showSituations:(NSArray*)situations withappDelegate:(OBAApplicationDelegate*)appDelegate navigationController:(UINavigationController*)navigationController args:(NSDictionary*)args {
    if( [situations count] == 1 ) {
        OBASituationV2 * situation = [situations objectAtIndex:0];
        OBASituationViewController * vc = [[OBASituationViewController alloc] initWithApplicationDelegate:appDelegate situation:situation];
        vc.args = args;
        [navigationController pushViewController:vc animated:YES];
    }
    else {
        OBASituationsViewController * vc = [[OBASituationsViewController alloc] initWithApplicationDelegate:appDelegate situations:situations];
        vc.args = args;
        [navigationController pushViewController:vc animated:YES];
    }
}

- (instancetype) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate situations:(NSArray*)situations {
    
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _appDelegate = appDelegate;
        _situations = situations;
        self.navigationItem.title = NSLocalizedString(@"Service Alerts",@"self.navigationItem.title");
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self hideEmptySeparators];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [OBAAnalytics reportViewController:self];
}

#pragma mark - View lifecycle

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_situations.count == 0) {
        return 1;
    }
    else {
        return _situations.count;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( [_situations count] == 0 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = NSLocalizedString(@"No active service alerts",@"cell.textLabel.text");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;            
    }
    
    OBASituationV2 * situation = _situations[indexPath.row];
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.text = situation.summary;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( [_situations count] > 0) {
        OBASituationV2 * situation = _situations[indexPath.row];
        OBASituationViewController * vc = [[OBASituationViewController alloc] initWithApplicationDelegate:_appDelegate situation:situation];
        vc.args = self.args;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end

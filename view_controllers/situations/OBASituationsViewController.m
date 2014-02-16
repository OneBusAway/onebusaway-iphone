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


@implementation OBASituationsViewController


#pragma mark -
#pragma mark Initialization

@synthesize args;

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate situations:(NSArray*)situations {
    
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
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark -
#pragma mark View lifecycle

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int count = [_situations count];
    if( count == 0 )
        count = 1;
    return count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( [_situations count] == 0 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = NSLocalizedString(@"No active service alerts",@"cell.textLabel.text");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;            
    }
    
    OBASituationV2 * situation = _situations[indexPath.row];
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.text = situation.summary;
    cell.textLabel.textAlignment = UITextAlignmentCenter;
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

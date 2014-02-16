/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBARecentStopsViewController.h"
#import "OBAStopAccessEventV2.h"
#import "OBAStopViewController.h"
#import "UITableViewController+oba_Additions.h"


@implementation OBARecentStopsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];

    if (self) {
        self.title = NSLocalizedString(@"Recent", @"Recent stops tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Clock"];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _mostRecentStops = [[NSArray alloc] init];
    [self hideEmptySeparators];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
 
    OBAModelDAO * modelDao = _appDelegate.modelDao;    
    _mostRecentStops = modelDao.mostRecentStops;
    [self.tableView reloadData];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int count = [_mostRecentStops count];
    if( count == 0 ) 
        count = 1;
    return count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( [_mostRecentStops count] == 0 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = NSLocalizedString(@"No recent stops",@"cell.textLabel.text");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
        OBAStopAccessEventV2 * event = _mostRecentStops[indexPath.row];
        cell.textLabel.text = event.title;
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.detailTextLabel.text = event.subtitle;
        cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.row;    
    if( 0 <= index && index < [_mostRecentStops count] ) {
        OBAStopAccessEventV2 * event = _mostRecentStops[index];
        OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationDelegate:_appDelegate stopId:event.stopIds[0]];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeRecentStops];
}

@end


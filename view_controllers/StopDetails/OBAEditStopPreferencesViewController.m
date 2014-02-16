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

#import "OBAEditStopPreferencesViewController.h"
#import "OBALogger.h"
#import "OBARouteV2.h"
#import "OBAStopViewController.h"
#import "UITableViewController+oba_Additions.h"


@implementation OBAEditStopPreferencesViewController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate stop:(OBAStopV2*)stop {

    if (self = [super initWithStyle:UITableViewStylePlain]) {
        
        _appDelegate = appDelegate;
        _stop = stop;
        
        UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelButton:)];
        [self.navigationItem setLeftBarButtonItem:cancelButton];
        
        UIBarButtonItem * saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSaveButton:)];
        [self.navigationItem setRightBarButtonItem:saveButton];
        
        self.navigationItem.title = NSLocalizedString(@"Filter & Sort",@"self.navigationItem.title");
        
        NSMutableArray * routes = [NSMutableArray array];
        for( OBARouteV2 * route in stop.routes)
            [routes addObject:route];
        [routes sortUsingSelector:@selector(compareUsingName:)];
        _routes = routes;
        
        OBAModelDAO * dao = _appDelegate.modelDao;
        _preferences = [dao stopPreferencesForStopWithId:stop.stopId];
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self hideEmptySeparators];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    view.backgroundColor = OBAGREENBACKGROUND;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
    title.font = [UIFont systemFontOfSize:18];
    title.backgroundColor = [UIColor clearColor];;
    switch(section) {
        case 0:
            title.text =  NSLocalizedString(@"Sort",@"section == 0");
            break;
        case 1:
            title.text = NSLocalizedString(@"Show Routes",@"section == 1");
            break;
            
    }
    [view addSubview:title];
    return view;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return 2;
        case 1:
        {
            int c = [_routes count];
            if( c == 0 )
                c = 1;
            return c;
        }
    }
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch(indexPath.section) {
        case 0:
            return [self tableView:tableView sortByCellForRowAtIndexPath:indexPath];
        case 1:
            return [self tableView:tableView routeCellForRowAtIndexPath:indexPath];
        default:
        {
            UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
            cell.textLabel.text = NSLocalizedString(@"Unknown cell",@"cell.textLabel.text");
            return cell;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView sortByCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    BOOL checked = NO;
    
    switch(indexPath.row) {
        case OBASortTripsByDepartureTimeV2:
            checked = _preferences.sortTripsByType == OBASortTripsByDepartureTimeV2;
            cell.textLabel.text = NSLocalizedString(@"Departure Time",@"OBASortTripsByDepartureTimeV2");
            break;
        case OBASortTripsByRouteNameV2:
            checked = _preferences.sortTripsByType == OBASortTripsByRouteNameV2;
            cell.textLabel.text = NSLocalizedString(@"Route",@"OBASortTripsByRouteNameV2");
            break;
        default:
            cell.textLabel.text = NSLocalizedString(@"Unknown cell",@"cell.textLabel.text");
    }

    cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView routeCellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if( [_routes count] == 0 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = NSLocalizedString(@"No routes at this stop",@"[_routes count] == 0");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    OBARouteV2 * route = _routes[indexPath.row];
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.text = [route safeShortName];
    
    BOOL checked = [_preferences isRouteIdEnabled:route.routeId];
    cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( indexPath.section == 0) {
        if( _preferences.sortTripsByType != indexPath.row ) {
            _preferences.sortTripsByType = indexPath.row;
            for( int i=0; i<2; i++) {
                NSIndexPath * cellIndex = [NSIndexPath indexPathForRow:i inSection:0];
                BOOL checked = (i == indexPath.row);
                
                UITableViewCell * cell = [tableView cellForRowAtIndexPath:cellIndex];
                cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
    }
    else if(indexPath.section == 1) {

        if( [_routes count] == 0)
            return;
        
        OBARouteV2 * route = _routes[indexPath.row];
        BOOL currentlyChecked = [_preferences isRouteIdEnabled:route.routeId];
        currentlyChecked = ! currentlyChecked;
        [_preferences setEnabled:currentlyChecked forRouteId:route.routeId];
        
        UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = currentlyChecked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (IBAction) onCancelButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) onSaveButton:(id)sender {
    
    OBAModelDAO * dao = _appDelegate.modelDao;
    [dao setStopPreferences:_preferences forStopWithId:_stop.stopId];
    
    // pop to stop view controller are saving settings
    BOOL foundStopViewController = NO;
    for (UIViewController* viewController in [self.navigationController viewControllers])
    {
        if ([viewController isKindOfClass:[OBAStopViewController class]])
        {
            [self.navigationController popToViewController:viewController animated:YES];
            foundStopViewController = YES;
            break;
        }
    }
    
    if (!foundStopViewController)
        [self.navigationController popViewControllerAnimated:YES];
}

@end


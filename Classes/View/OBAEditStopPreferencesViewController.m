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
#import "OBAUITableViewCell.h"
#import "OBAStopViewController.h"


@implementation OBAEditStopPreferencesViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stop:(OBAStopV2*)stop {

    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		
		_appContext = [appContext retain];
		_stop = [stop retain];
		
		UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelButton:)];
		[self.navigationItem setLeftBarButtonItem:cancelButton];
		[cancelButton release];
		
		UIBarButtonItem * saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSaveButton:)];
		[self.navigationItem setRightBarButtonItem:saveButton];
		[saveButton release];
		
		self.navigationItem.title = @"Filter & Sort";
		
		NSMutableArray * routes = [NSMutableArray array];
		for( OBARouteV2 * route in stop.routes)
			[routes addObject:route];
		[routes sortUsingSelector:@selector(compareUsingName:)];
		_routes = [routes retain];
		
		OBAModelDAO * dao = _appContext.modelDao;
		_preferences = [dao stopPreferencesForStopWithId:stop.stopId];
		[_preferences retain];
    }
    return self;
}

- (void)dealloc {
	[_appContext release];
	[_stop release];
	[_routes release];
	[_preferences release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if( section == 0)
		return @"Sort";
	else if( section == 1)
		return @"Show Routes";
	return nil;
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
			cell.textLabel.text = @"Unknown cell";
			return cell;
		}
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView sortByCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	BOOL checked = FALSE;
	
	switch(indexPath.row) {
		case OBASortTripsByDepartureTimeV2:
			checked = _preferences.sortTripsByType == OBASortTripsByDepartureTimeV2;
			cell.textLabel.text = @"Departure Time";
			break;
		case OBASortTripsByRouteNameV2:
			checked = _preferences.sortTripsByType == OBASortTripsByRouteNameV2;
			cell.textLabel.text = @"Route";
			break;
		default:
			cell.textLabel.text = @"Unknown cell";
	}

	cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView routeCellForRowAtIndexPath:(NSIndexPath *)indexPath {

	if( [_routes count] == 0 ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.text = @"No routes at this stop";
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	}
	
	OBARouteV2 * route = [_routes objectAtIndex:indexPath.row];
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.text = [route safeShortName];
	
	BOOL checked = [_preferences isRouteIdEnabled:route.routeId];
	cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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
				[tableView deselectRowAtIndexPath:indexPath animated:TRUE];
			}
		}
	}
	else if(indexPath.section == 1) {

		if( [_routes count] == 0)
			return;
		
		OBARouteV2 * route = [_routes objectAtIndex:indexPath.row];
		BOOL currentlyChecked = [_preferences isRouteIdEnabled:route.routeId];
		currentlyChecked = ! currentlyChecked;
		[_preferences setEnabled:currentlyChecked forRouteId:route.routeId];
		
		UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
		cell.accessoryType = currentlyChecked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		[tableView deselectRowAtIndexPath:indexPath animated:TRUE];
	}
}

- (IBAction) onCancelButton:(id)sender {
	[self.navigationController popViewControllerAnimated:TRUE];
}

- (IBAction) onSaveButton:(id)sender {
	
	OBAModelDAO * dao = _appContext.modelDao;
	[dao setStopPreferences:_preferences forStopWithId:_stop.stopId];
	
	// pop to stop view controller are saving settings
	BOOL foundStopViewController = FALSE;
	for (UIViewController* viewController in [self.navigationController viewControllers])
	{
		if ([viewController isKindOfClass:[OBAStopViewController class]])
		{
			[self.navigationController popToViewController:viewController animated:TRUE];
			foundStopViewController = TRUE;
			break;
		}
	}
	
	if (!foundStopViewController)
		[self.navigationController popViewControllerAnimated:TRUE];
}

@end


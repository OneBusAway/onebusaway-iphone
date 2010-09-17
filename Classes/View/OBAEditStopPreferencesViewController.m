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
#import "OBARoute.h"
#import "OBAUITableViewCell.h"


@implementation OBAEditStopPreferencesViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stop:(OBAStop*)stop {

    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		
		_appContext = [appContext retain];
		_stop = [stop retain];
		
		UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelButton:)];
		[self.navigationItem setLeftBarButtonItem:cancelButton];
		[cancelButton release];
		
		UIBarButtonItem * saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSaveButton:)];
		[self.navigationItem setRightBarButtonItem:saveButton];
		[saveButton release];
		
		self.navigationItem.title = @"Filter";
		
		NSMutableArray * routes = [NSMutableArray array];
		for( OBARoute * route in stop.routes)
			[routes addObject:route];
		[routes sortUsingSelector:@selector(compareUsingName:)];
		_routes = [routes retain];
    }
    return self;
}

- (void)dealloc {
	[_appContext release];
	[_stop release];
	[_routes release];
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
		return @"Sort By:";
	else if( section == 1)
		return @"Routes:";
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
	cell.textLabel.text = @"Unknown cell";
	
	OBAStopPreferences * prefs = _stop.preferences;
	
	switch(indexPath.row) {
		case OBASortTripsByDepartureTime:
			checked = [prefs.sortTripsByType intValue] == OBASortTripsByDepartureTime;
			cell.textLabel.text = @"Departure Time";
			break;
		case OBASortTripsByRouteName:
			checked = [prefs.sortTripsByType intValue] == OBASortTripsByRouteName;
			cell.textLabel.text = @"Route";
			break;
	}

	cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
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
	
	OBARoute * route = [_routes objectAtIndex:indexPath.row];
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.text = route.shortName;
	
	OBAStopPreferences * prefs = _stop.preferences;
	
	BOOL checked = ! [prefs.routesToExclude containsObject:route];
	cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBAStopPreferences * prefs = _stop.preferences;
	
	if( indexPath.section == 0) {
		if( [prefs.sortTripsByType intValue] != indexPath.row ) {
			prefs.sortTripsByType = [NSNumber numberWithInteger:indexPath.row];
			for( int i=0; i<2; i++) {
				NSIndexPath * cellIndex = [NSIndexPath indexPathForRow:i inSection:0];
				UITableViewCell * cell = [tableView cellForRowAtIndexPath:cellIndex];
				BOOL checked = (i == indexPath.row);
				cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			}
		}
	}
	else if(indexPath.section == 1) {

		if( [_routes count] == 0)
			return;
		
		OBARoute * route = [_routes objectAtIndex:indexPath.row];
		BOOL currentlyChecked = ! [prefs.routesToExclude containsObject:route];
		currentlyChecked = ! currentlyChecked;
		
		if( currentlyChecked )
			[prefs removeRoutesToExcludeObject:route];
		else
			[prefs addRoutesToExcludeObject:route];
		
		UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
		cell.accessoryType = currentlyChecked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	}
}

- (IBAction) onCancelButton:(id)sender {
	[_appContext.modelDao rollback];
	[self.navigationController popViewControllerAnimated:TRUE];
}

- (IBAction) onSaveButton:(id)sender {
	
	OBAModelDAO * dao = _appContext.modelDao;
	NSError * error = nil;
	[dao saveIfNeeded:&error];
	if( error )
		OBALogSevereWithError(error,@"Error saving stop preferences");
	[self.navigationController popViewControllerAnimated:TRUE];
}

@end


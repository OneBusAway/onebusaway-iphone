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
#import "OBAStopAccessEvent.h"
#import "OBAUIKit.h"
#import "OBAStopTableViewCell.h"
#import "OBAUITableViewCell.h"
#import "OBAStopViewController.h"


@implementation OBARecentStopsViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
	if( self = [super initWithStyle:UITableViewStyleGrouped] ) {
		_appContext = [appContext retain];
		_mostRecentStops = [[NSArray alloc] init];
	}
	return self;
}

- (void)dealloc {	
	[_appContext release];
	[_mostRecentStops release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.title = @"Recent Stops"; 
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
 
	OBAModelDAO * modelDao = _appContext.modelDao;	
	_mostRecentStops = [NSObject releaseOld:_mostRecentStops retainNew:modelDao.mostRecentStops];
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
		cell.textLabel.text = @ "No recent stops";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	}
	else {
		OBAStopTableViewCell * cell = [OBAStopTableViewCell getOrCreateCellForTableView:tableView];
		OBAStopAccessEvent * event = [_mostRecentStops objectAtIndex:indexPath.row];
		[cell setStop:event.stop];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger index = indexPath.row;	
	if( 0 <= index && index < [_mostRecentStops count] ) {
		OBAStopAccessEvent * event = [_mostRecentStops objectAtIndex:index];
		OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationContext:_appContext stop:event.stop];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeRecentStops];
}

@end


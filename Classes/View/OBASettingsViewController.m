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

#import "OBASettingsViewController.h"
#import "OBAUITableViewCell.h"
#import "OBASearchController.h"
#import "OBAActivityLoggingViewController.h"


@implementation OBASettingsViewController

@synthesize appContext = _appContext;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [appContext retain];
	}
    return self;
}

- (void) dealloc {
	[_appContext release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return kIncludeUWActivityInferenceCode ? 2 : 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if( indexPath.row == 0 ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"Supported Agencies";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
	else if( indexPath.row == 1 && kIncludeUWActivityInferenceCode) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"Activity";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
	else {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"Unknown";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch(indexPath.row) {
		case 0: {
			OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchAgenciesWithCoverage];
			[_appContext navigateToTarget:target];
			break;
		}
		case 1: {
			if( kIncludeUWActivityInferenceCode ) {
				OBAActivityLoggingViewController * vc = [[OBAActivityLoggingViewController alloc] initWithApplicationContext:_appContext];
				[self.navigationController pushViewController:vc animated:TRUE];
				[vc release];
			}
			break;
		}
	}
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeSettings];
}

@end


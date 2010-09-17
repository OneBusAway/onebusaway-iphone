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
#import "OBAContactUsViewController.h"

#import "ISFeedback.h"


typedef enum {
	OBARowNone, OBARowAgencies, OBARowContactUs, OBARowFeedback, OBARowLocationAware, OBARowActivityAware
} OBARowType;


@interface OBASettingsViewController (Internal)

- (OBARowType) rowTypeForRowIndex:(NSInteger)row;

@end


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
	NSInteger rows = 3;
	if( kIncludeUWUserStudyCode )
		rows += 1;
	if( kIncludeUWActivityInferenceCode)
		rows += 1;
	return rows;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	OBARowType rowType = [self rowTypeForRowIndex:indexPath.row];
	
	if( rowType == OBARowAgencies ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"Supported Agencies";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
	else if( rowType == OBARowContactUs ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"Contact Us";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
	else if( rowType == OBARowFeedback ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"Feedback";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}		
	else if( rowType == OBARowLocationAware ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"Location Aware";
		cell.accessoryType =_appContext.locationAware ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		return cell;
	}
	else if( rowType == OBARowActivityAware ) {
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
	
	OBARowType rowType = [self rowTypeForRowIndex:indexPath.row];
	
	switch(rowType) {
		case OBARowAgencies: {
			OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchAgenciesWithCoverage];
			[_appContext navigateToTarget:target];
			break;
		}
		case OBARowContactUs: {
			OBAContactUsViewController * vc = [[OBAContactUsViewController alloc] initWithApplicationContext:_appContext];
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
		case OBARowFeedback: {
			[[ISFeedback sharedInstance] pushOntoViewController:self];
			break;
		}
		case OBARowLocationAware: {
			_appContext.locationAware = ! _appContext.locationAware;
			[self.tableView reloadData];
			break;
		}
		case OBARowActivityAware: {
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


@implementation OBASettingsViewController (Internal)

- (OBARowType) rowTypeForRowIndex:(NSInteger) row {
	if( row == 0 )
		return OBARowFeedback;
	if( row == 1 )
		return OBARowContactUs;	
	if( row == 2 )
		return OBARowAgencies;
	if( kIncludeUWActivityInferenceCode && kIncludeUWUserStudyCode ) {
		if( row == 3 )
			return OBARowLocationAware;
		if( row == 4 )
			return OBARowActivityAware;
	}
	else if( kIncludeUWActivityInferenceCode ) {
		if( row == 3 )
			return OBARowActivityAware;
	}
	else if( kIncludeUWUserStudyCode ) {
		if( row == 4 )
			return OBARowLocationAware;
	}
		
	return OBARowNone;
}

@end



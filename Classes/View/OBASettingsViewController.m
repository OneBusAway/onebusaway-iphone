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
#import "OBAContactUsViewController.h"

#import "ISFeedback.h"


typedef enum {
	OBARowNone,
	OBARowFeedback,
	OBARowContactUs,
	OBARowSettings,
	OBARowAgencies
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

#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([ISFeedback sharedInstance] == nil)
        [ISFeedback initSharedInstance:@"b1b94280-e1bf-4d7c-a657-72aa1d25e49e"];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 4;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	OBARowType rowType = [self rowTypeForRowIndex:indexPath.row];
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	if( rowType == OBARowAgencies ) {
		cell.textLabel.text = @"Supported Agencies";
	}
	else if( rowType == OBARowContactUs ) {
		cell.textLabel.text = @"Contact Us";
	}
	else if( rowType == OBARowFeedback ) {
		cell.textLabel.text = @"Suggest an Idea";
	}
	else if( rowType == OBARowSettings ) {
		cell.textLabel.text = @"Settings";
	}	
	else {
		cell.textLabel.text = @"Unknown";
	}
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBARowType rowType = [self rowTypeForRowIndex:indexPath.row];
	
	switch(rowType) {
		case OBARowAgencies: {
			OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchAgenciesWithCoverage];
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
		case OBARowSettings: {
			IASKAppSettingsViewController * vc = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
			vc.showDoneButton = NO;
			vc.delegate = self;
			[self.navigationController pushViewController:vc animated:YES];
			break;
		}
	}
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeSettings];
}

#pragma mark IASKSettingsDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
	[_appContext refreshSettings];
}

@end


@implementation OBASettingsViewController (Internal)

- (OBARowType) rowTypeForRowIndex:(NSInteger) row {
	if( row == 0 )
		return OBARowFeedback;
	if( row == 1 )
		return OBARowContactUs;	
	if( row == 2 )
		return OBARowSettings;
	if( row == 3 )
		return OBARowAgencies;
	
	return OBARowNone;
}

@end



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

#import "OBAActivityLoggingViewController.h"
#import "OBAUITableViewCell.h"
#import "OBAActivityAnnotationViewController.h"
#import "OBAUploadViewController.h"
#import "OBALockViewController.h"
#import "OBACurrentActivityViewController.h"


@implementation OBAActivityLoggingViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
	if( self = [super initWithStyle:UITableViewStyleGrouped] ) {
		_appContext = [appContext retain];
	}
	return self;
}

- (void)dealloc {
	[_appContext release];
    [super dealloc];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? 4 : 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	switch(indexPath.section) {
		case 0: {
			switch(indexPath.row) {
				case 0:
					cell.textLabel.text = @"Annotate Activity";
					break;
				case 1:
					cell.textLabel.text = @"Upload Data";
					break;
				case 2:
					cell.textLabel.text = @"Lock Screen";
					break;
				case 3:
					cell.textLabel.text = @"Activity Display";
					break;
			}
			break;
		}		
		case 1: {
			cell.textLabel.text = @"Delete All Data";
			break;
		}
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	UINavigationController * vc = nil;
	
	switch (indexPath.section ) {
		case 0: {
			switch (indexPath.row) {
				case 0:
					vc = [[OBAActivityAnnotationViewController alloc] initWithApplicationContext:_appContext];
					break;
				case 1:
					vc = [[OBAUploadViewController alloc] initWithApplicationContext:_appContext];
					break;
				case 2:
					vc = [[OBALockViewController alloc] initWithApplicationContext:_appContext];
					break;
				case 3:
					vc = [[OBACurrentActivityViewController alloc] initWithApplicationContext:_appContext];
					break;
				default:
					vc = [[OBAActivityAnnotationViewController alloc] initWithApplicationContext:_appContext];
					break;			
			}
			break;
		}
		case 1: {
			UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"Really delete?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
			[sheet showInView:self.view];
			break;
		}
	}
	
	[self.navigationController pushViewController:vc animated:TRUE];
	[vc release];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeActivityLogging];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if( buttonIndex == 0 ) {
		OBAActivityLogger * logger = [OBAActivityLogger getLogger];
		[logger deleteAllTraces];
	}
}

@end


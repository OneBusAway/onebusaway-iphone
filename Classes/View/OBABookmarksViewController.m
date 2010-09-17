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

#import "OBABookmarksViewController.h"
#import "OBAUITableViewCell.h"
#import "OBAUIKit.h"
#import "OBALogger.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBAStopViewController.h"


@interface OBABookmarksViewController (Private)

- (void) refreshBookmarks;
- (void) abortEditing;

@end


@implementation OBABookmarksViewController

@synthesize appContext = _appContext;
@synthesize customEditButtonItem = _customEditButtonItem;

- (void)dealloc {
	[_appContext release];
	[_bookmarks release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	// We reload the table here in case we are coming back from the user editing the label for a bookmark
	[self refreshBookmarks];
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {	
	int count = [_bookmarks count];
	if( count == 0 )
		count = 1;
	return count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if( [_bookmarks count] == 0 ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"No bookmarks set";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.accessoryType = UITableViewCellAccessoryNone;		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	}
	else {
		OBABookmarkV2 * bookmark = [_bookmarks objectAtIndex:(indexPath.row)];
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = bookmark.name;
		cell.textLabel.textAlignment = UITextAlignmentLeft;		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		return cell;
	}
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
	if( [_bookmarks count] == 0 )
		return;
	
	OBABookmarkV2 * bookmark = [_bookmarks objectAtIndex:(indexPath.row)];
	
	if( self.tableView.editing ) {
		OBAEditStopBookmarkViewController * vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationContext:_appContext bookmark:bookmark editType:OBABookmarkEditExisting];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
	else {
		[_appContext.activityListeners bookmarkClicked:bookmark];
		OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationContext:_appContext stopIds:bookmark.stopIds];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath  {
	
	OBAModelDAO * modelDao = _appContext.modelDao;
	OBABookmarkV2 * bookmark = [_bookmarks objectAtIndex:(indexPath.row)];
	NSError * error = nil;
	[modelDao removeBookmark:bookmark error:&error];
	if( error ) 
		OBALogSevereWithError(error,@"Error removing bookmark");
	[self refreshBookmarks];
	
	if( [_bookmarks count] > 0 ) {
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
						 withRowAnimation:UITableViewRowAnimationFade];
	}
	else {
		[self performSelector:@selector(abortEditing) withObject:nil afterDelay:0.1];
	}
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

-(void) tableView: (UITableView *) tableView moveRowAtIndexPath: (NSIndexPath *) oldPath toIndexPath:(NSIndexPath *) newPath {
	
	OBAModelDAO * modelDao = _appContext.modelDao;
	NSError * error = nil;
	[modelDao moveBookmark:oldPath.row to: newPath.row error:&error];
	if( error ) 
		OBALogSevereWithError(error,@"Error moving bookmark");
	[self refreshBookmarks];
}

- (IBAction) onEditButton:(id)sender {
	
	BOOL isEditing = ! self.editing;
	[self setEditing:isEditing animated:TRUE];

	if( isEditing ) {
		_customEditButtonItem.title = @"Done";
		_customEditButtonItem.style = UIBarButtonItemStyleDone;
	}
	else {
		_customEditButtonItem.title = @"Edit";
		_customEditButtonItem.style = UIBarButtonItemStyleBordered;
	}
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeBookmarks];
}

@end

@implementation OBABookmarksViewController (Private)

- (void) refreshBookmarks {
	
	OBAModelDAO * dao = _appContext.modelDao;
	_bookmarks = [NSObject releaseOld:_bookmarks retainNew:dao.bookmarks];
	
	_customEditButtonItem.enabled = [_bookmarks count] > 0;
}
		
- (void) abortEditing {
	self.editing = FALSE;
	[self.tableView setEditing:FALSE animated:FALSE];

	_customEditButtonItem.title = @"Edit";
	_customEditButtonItem.style = UIBarButtonItemStyleBordered;
	
	[self.tableView reloadData];
}	

@end


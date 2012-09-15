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
#import "OBALogger.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBAStopViewController.h"


@interface OBABookmarksViewController ()
@property(strong) NSArray *bookmarks;
- (void)_refreshBookmarks;
- (void)_abortEditing;
@end


@implementation OBABookmarksViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    if (self)
    {
        self.title = NSLocalizedString(@"Bookmarks", @"Bookmarks tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Bookmarks"];
        self.bookmarks = [NSArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	// We reload the table here in case we are coming back from the user editing the label for a bookmark
	[self _refreshBookmarks];
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return MAX(self.bookmarks.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];

	if( 0 == self.bookmarks.count ) {
		cell.textLabel.text = NSLocalizedString(@"No bookmarks set",@"[_bookmarks count] == 0");
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.accessoryType = UITableViewCellAccessoryNone;		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	else {
		OBABookmarkV2 * bookmark = self.bookmarks[(indexPath.row)];
        
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = bookmark.name;
		cell.textLabel.textAlignment = UITextAlignmentLeft;		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
	if (0 == self.bookmarks.count)
    {
        return;
    }
	
	OBABookmarkV2 * bookmark = self.bookmarks[(indexPath.row)];
	
	if( self.tableView.editing ) {
		OBAEditStopBookmarkViewController * vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationContext:self.appContext bookmark:bookmark editType:OBABookmarkEditExisting];
		[self.navigationController pushViewController:vc animated:YES];
	}
	else {
		[self.appContext.activityListeners bookmarkClicked:bookmark];
		OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationContext:self.appContext stopIds:bookmark.stopIds];
		[self.navigationController pushViewController:vc animated:YES];
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath  {
	
	OBAModelDAO * modelDao = self.appContext.modelDao;
	OBABookmarkV2 * bookmark = self.bookmarks[(indexPath.row)];
    
	NSError * error = nil;
	[modelDao removeBookmark:bookmark error:&error];
	if( error ) 
		OBALogSevereWithError(error,@"Error removing bookmark");
	[self _refreshBookmarks];
	
	if( [self.bookmarks count] > 0 ) {
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] 
						 withRowAnimation:UITableViewRowAnimationFade];
	}
	else {
		[self performSelector:@selector(_abortEditing) withObject:nil afterDelay:0.1];
	}
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

-(void) tableView: (UITableView *) tableView moveRowAtIndexPath: (NSIndexPath *) oldPath toIndexPath:(NSIndexPath *) newPath {
	
	OBAModelDAO * modelDao = self.appContext.modelDao;
	NSError * error = nil;
	[modelDao moveBookmark:oldPath.row to: newPath.row error:&error];
	if( error ) 
		OBALogSevereWithError(error,@"Error moving bookmark");
	[self _refreshBookmarks];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeBookmarks];
}

#pragma mark - Private

- (void) _refreshBookmarks {
	OBAModelDAO * dao = self.appContext.modelDao;
    self.bookmarks = dao.bookmarks;
	self.editButtonItem.enabled = [self.bookmarks count] > 0;
}
		
- (void)_abortEditing {
	self.editing = NO;
	[self.tableView setEditing:NO animated:NO];	
	[self.tableView reloadData];
}	

@end


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
#import "UITableViewController+oba_Additions.h"
#import "OBABookmarkGroup.h"
#import "OBAEditBookmarkGroupViewController.h"

@interface OBABookmarksViewController ()
@property(strong) NSArray *bookmarks;
@property(strong) NSArray *bookmarkGroups;
@property (nonatomic, strong) NSMutableArray *collapsedGroups;
- (void)_refreshBookmarks;
- (void)_abortEditing;
@end


@implementation OBABookmarksViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];

    if (self) {
        self.title = NSLocalizedString(@"Bookmarks", @"Bookmarks tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Bookmarks"];
        self.bookmarks = [NSArray array];
        self.bookmarkGroups = [NSArray array];
        self.tableView.allowsSelectionDuringEditing = YES;
        self.collapsedGroups = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [self hideEmptySeparators];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    // We reload the table here in case we are coming back from the user editing the label for a bookmark
    [self _refreshBookmarks];
    [self.tableView reloadData];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (id)objectAtRow:(NSInteger)row {
    NSInteger iter = 0;
    for (OBABookmarkGroup *group in self.bookmarkGroups) {
        if (iter == row) return group;
        iter++;
        if (![self.collapsedGroups containsObject:group]) {
            if ((row - iter) < group.bookmarks.count) {
                return group.bookmarks[row - iter];
            } else {
                iter += group.bookmarks.count;
            }
        }
    }
    return self.bookmarks[row - iter];
}

- (NSInteger)numberOfRowsForBookmarkGroups {
    NSInteger total = 0;
    for (OBABookmarkGroup *group in self.bookmarkGroups) {
        if ([self.collapsedGroups containsObject:group]) {
            total++;
        } else {
            total += group.bookmarks.count + 1;
        }
    }
    return total;
}

#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger total = self.bookmarks.count;
    total += [self numberOfRowsForBookmarkGroups];
    return MAX(total, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell * cell = nil;

    if( 0 == self.bookmarks.count && 0 == self.bookmarkGroups.count ) {
        cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = NSLocalizedString(@"No bookmarks set",@"[_bookmarks count] == 0");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else {
        id obj = [self objectAtRow:indexPath.row];
        if ([obj isKindOfClass:[OBABookmarkV2 class]]) {
            OBABookmarkV2 * bookmark = (OBABookmarkV2*)obj;
            
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([self class])];
            
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([self class])];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.textLabel.text = bookmark.name ? bookmark.name : @"NO NAME";
        } else {
            OBABookmarkGroup * group = (OBABookmarkGroup*)obj;
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"BookmarkGroup"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"BookmarkGroup"];
            }
            cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
            cell.textLabel.text = group.name ? group.name : @"NO NAME";
            cell.detailTextLabel.text = [self.collapsedGroups containsObject:group] ? @">" : @"v";
        }
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.bookmarkGroups.count == 0 && self.bookmarks.count == 0) return 0;
    id obj = [self objectAtRow:indexPath.row];
    if ([obj isMemberOfClass:[OBABookmarkV2 class]] && [obj valueForKey:@"group"] != nil) {
        return 1;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (0 == self.bookmarks.count && 0 == self.bookmarkGroups.count) {
        return;
    }
    
    id obj = [self objectAtRow:indexPath.row];
    
    if ([obj isMemberOfClass:[OBABookmarkV2 class]]) {
        OBABookmarkV2 * bookmark = (OBABookmarkV2*)obj;
        
        if( self.tableView.editing ) {
            OBAEditStopBookmarkViewController * vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationDelegate:self.appDelegate bookmark:bookmark editType:OBABookmarkEditExisting];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else {
            OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationDelegate:self.appDelegate stopId:bookmark.stopIds[0]];
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else {
        OBABookmarkGroup *group = (OBABookmarkGroup*)obj;
        if (self.tableView.editing) {
            OBAEditBookmarkGroupViewController *editGroupVC = [[OBAEditBookmarkGroupViewController alloc] initWithApplicationDelegate:self.appDelegate bookmarkGroup:group editType:OBABookmarkGroupEditExisting];
            [self.navigationController pushViewController:editGroupVC animated:YES];
        } else {
            [self.tableView beginUpdates];
            if ([self.collapsedGroups containsObject:group]) {
                NSMutableArray *pathsToInsert = [NSMutableArray array];
                for (NSInteger i = indexPath.row + 1; i < indexPath.row + group.bookmarks.count + 1; i++) {
                    [pathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
                [self.collapsedGroups removeObject:group];
                [self.tableView insertRowsAtIndexPaths:pathsToInsert withRowAnimation:UITableViewRowAnimationFade];
            } else {
                NSMutableArray *pathsToDelete = [NSMutableArray array];
                for (NSInteger i = indexPath.row + 1; i < indexPath.row + group.bookmarks.count + 1; i++) {
                    [pathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
                [self.collapsedGroups addObject:group];
                [self.tableView deleteRowsAtIndexPaths:pathsToDelete withRowAnimation:UITableViewRowAnimationFade];
            }
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath  {
    
    OBAModelDAO * modelDao = self.appDelegate.modelDao;
    id obj = [self objectAtRow:indexPath.row];
    if ([obj isMemberOfClass:[OBABookmarkV2 class]]) {
        OBABookmarkV2 * bookmark = (OBABookmarkV2*)obj;
        
        [modelDao removeBookmark:bookmark];
        
        [self _refreshBookmarks];
        
        if( [self.bookmarks count] > 0 || self.bookmarkGroups.count > 0) {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        else {
            [self performSelector:@selector(_abortEditing) withObject:nil afterDelay:0.1];
        }
    } else {
        OBABookmarkGroup *group = (OBABookmarkGroup*)obj;
        NSInteger bmCount = group.bookmarks.count;
        
        [modelDao removeBookmarkGroup:group];
        [self _refreshBookmarks];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        NSIndexPath *sourceIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        NSIndexPath *destIndexPath = [NSIndexPath indexPathForRow:[tableView numberOfRowsInSection:0]-1 inSection:0];
        for (NSInteger i = 0; i < bmCount; i++) {
            [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destIndexPath];
        }
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:.5];
    }
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[self objectAtRow:indexPath.row] isMemberOfClass:[OBABookmarkV2 class]];
}

-(void) tableView: (UITableView *) tableView moveRowAtIndexPath: (NSIndexPath *) oldPath toIndexPath:(NSIndexPath *) newPath {
    OBABookmarkV2 *bookmark = [self objectAtRow:oldPath.row];
    OBAModelDAO * modelDao = self.appDelegate.modelDao;
    
    if (!bookmark.group) {
        NSInteger numOfGroupRows = [self numberOfRowsForBookmarkGroups];
        [modelDao moveBookmark:oldPath.row - numOfGroupRows to:newPath.row - numOfGroupRows];
    } else {
        OBABookmarkGroup *group = bookmark.group;
        NSInteger startIndex = [group.bookmarks indexOfObject:bookmark];
        NSInteger delta = newPath.row - oldPath.row;
        NSInteger finalIndex = startIndex + delta;
        [modelDao moveBookmark:startIndex to:finalIndex inGroup:group];
    }
    [self _refreshBookmarks];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    NSInteger sourceRow = sourceIndexPath.row;
    OBABookmarkV2 *bookmark = [self objectAtRow:sourceRow];
    if (!bookmark.group) {
        if (proposedDestinationIndexPath.row < [self numberOfRowsForBookmarkGroups]) {
            return [NSIndexPath indexPathForRow:[self numberOfRowsForBookmarkGroups] inSection:0];
        }
    } else {
        OBABookmarkGroup *group = bookmark.group;
        NSInteger groupRow = sourceRow - [group.bookmarks indexOfObject:bookmark] - 1;
        NSInteger finalRowOfGroup = groupRow + group.bookmarks.count;
        if (proposedDestinationIndexPath.row <= groupRow) {
            return [NSIndexPath indexPathForRow:groupRow + 1 inSection:0];
        } else if (proposedDestinationIndexPath.row > finalRowOfGroup) {
            return [NSIndexPath indexPathForRow:finalRowOfGroup inSection:0];
        }
    }
    return proposedDestinationIndexPath;
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeBookmarks];
}

#pragma mark - Private

- (BOOL)canEdit
{
    if (self.bookmarks.count > 0) return YES;
    else {
        for (OBABookmarkGroup *group in self.bookmarkGroups) {
            if (group.bookmarks.count > 0) return YES;
        }
    }
    return NO;
}

- (void) _refreshBookmarks {
    OBAModelDAO * dao = self.appDelegate.modelDao;
    self.bookmarks = dao.bookmarks;
    self.bookmarkGroups = dao.bookmarkGroups;
    self.editButtonItem.enabled = [self canEdit];
}
        
- (void)_abortEditing {
    self.editing = NO;
    [self.tableView setEditing:NO animated:NO];    
    [self.tableView reloadData];
}    

@end


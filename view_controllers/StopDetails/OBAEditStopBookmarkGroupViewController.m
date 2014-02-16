//
//  OBAEditStopBookmarkGroupViewController.m
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 12/19/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBAEditStopBookmarkGroupViewController.h"
#import "OBAModelDAO.h"
#import "OBABookmarkGroup.h"
#import "OBATextFieldTableViewCell.h"
#import "OBAEditBookmarkGroupViewController.h"
#import "OBAApplicationDelegate.h"

@interface OBAEditStopBookmarkGroupViewController ()

@end

@implementation OBAEditStopBookmarkGroupViewController

- (id)initWithAppDelegate:(OBAApplicationDelegate*)appDelegate selectedBookmarkGroup:(OBABookmarkGroup*)group {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _appDelegate = appDelegate;
        _groups = [appDelegate.modelDao bookmarkGroups];
        _selectedGroup = group;
        
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDoneButton:)];
        [self.navigationItem setRightBarButtonItem:doneButton];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    [self _refreshGroups];
    [self.tableView reloadData];
}

- (void)onDoneButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.groups.count + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Add";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"None";
        if (self.selectedGroup == nil) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        OBABookmarkGroup *group = self.groups[indexPath.row - 2];
        if (group == self.selectedGroup) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        cell.textLabel.text = group.name;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        OBABookmarkGroup *newGroup = [[OBABookmarkGroup alloc] initWithName:@"New Group"];
        if (!self.selectedGroup) {
            self.selectedGroup = newGroup;
            [self.delegate didSetBookmarkGroup:newGroup];
        }
        OBAEditBookmarkGroupViewController *editBookmarkGroupVC = [[OBAEditBookmarkGroupViewController alloc] initWithApplicationDelegate:self.appDelegate bookmarkGroup:newGroup editType:OBABookmarkGroupEditNew];
        [self.navigationController pushViewController:editBookmarkGroupVC animated:YES];
    } else if (indexPath.row == 1) {
        NSInteger oldGroupRow = self.selectedGroup ? ([self.groups indexOfObject:self.selectedGroup]+2) : -1;
        self.selectedGroup = nil;
        [self.delegate didSetBookmarkGroup:nil];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (oldGroupRow != -1) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:oldGroupRow inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } else {
        if (self.editing) {
            OBAEditBookmarkGroupViewController *editBookmarkGroupVC = [[OBAEditBookmarkGroupViewController alloc] initWithApplicationDelegate:self.appDelegate bookmarkGroup:self.groups[indexPath.row - 2] editType:OBABookmarkGroupEditExisting];
            [[GAI sharedInstance].defaultTracker
             send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                          action:@"edit_field"
                                                           label:@"Edited Bookmark Group"
                                                           value:nil] build]];
            [self.navigationController pushViewController:editBookmarkGroupVC animated:YES];
        } else {
            NSInteger oldGroupRow = self.selectedGroup ? ([self.groups indexOfObject:self.selectedGroup]+2) : 1;
            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldGroupRow inSection:0];
            self.selectedGroup = self.groups[indexPath.row - 2];
            [self.delegate didSetBookmarkGroup:self.selectedGroup];
            if ([indexPath isEqual:oldIndexPath]) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath, oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row > 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OBABookmarkGroup *group = self.groups[indexPath.row - 2];
        if (self.selectedGroup == group) {
            self.selectedGroup = nil;
            [self.delegate didSetBookmarkGroup:nil];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.appDelegate.modelDao removeBookmarkGroup:group];
        [self _refreshGroups];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Private

- (void)_refreshGroups {
    self.groups = [self.appDelegate.modelDao bookmarkGroups];
    self.editButtonItem.enabled = (self.groups.count > 0);
}
@end

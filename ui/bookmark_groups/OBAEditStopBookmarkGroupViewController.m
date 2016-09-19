//
//  OBAEditStopBookmarkGroupViewController.m
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 12/19/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBAEditStopBookmarkGroupViewController.h"
#import <OBAKit/OBAKit.h>
#import "OBATextFieldTableViewCell.h"
#import "OBAEditBookmarkGroupViewController.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"

@implementation OBAEditStopBookmarkGroupViewController

- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO selectedBookmarkGroup:(OBABookmarkGroup*)group {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _modelDAO = modelDAO;
        _selectedGroup = group;

        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDoneButton:)];
        [self.navigationItem setRightBarButtonItem:doneButton];
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    [self _refreshGroups];
    [self.tableView reloadData];
}

- (void)onDoneButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modelDAO.bookmarkGroups.count + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryNone;

    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Add",);
    }
    else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"None",);

        if (self.selectedGroup == nil) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    else {
        OBABookmarkGroup *group = self.modelDAO.bookmarkGroups[indexPath.row - 2];

        if (group == self.selectedGroup) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }

        cell.textLabel.text = group.name;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        OBABookmarkGroup *newGroup = [[OBABookmarkGroup alloc] initWithName:@"New Group"];

        if (!self.selectedGroup) {
            self.selectedGroup = newGroup;
            [self.delegate didSetBookmarkGroup:newGroup];
        }

        OBAEditBookmarkGroupViewController *editBookmarkGroupVC = [[OBAEditBookmarkGroupViewController alloc] initWithBookmarkGroup:newGroup editType:OBABookmarkGroupEditNew];
        [self.navigationController pushViewController:editBookmarkGroupVC animated:YES];
    }
    else if (indexPath.row == 1) {
        NSInteger oldGroupRow = self.selectedGroup ? ([self.modelDAO.bookmarkGroups indexOfObject:self.selectedGroup] + 2) : -1;
        self.selectedGroup = nil;
        [self.delegate didSetBookmarkGroup:nil];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

        if (oldGroupRow != -1) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:oldGroupRow inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    else {
        if (self.editing) {
            OBAEditBookmarkGroupViewController *editBookmarkGroupVC = [[OBAEditBookmarkGroupViewController alloc] initWithBookmarkGroup:self.modelDAO.bookmarkGroups[indexPath.row - 2] editType:OBABookmarkGroupEditExisting];
            [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"edit_field" label:@"Edited Bookmark Group" value:nil];
            [self.navigationController pushViewController:editBookmarkGroupVC animated:YES];
        }
        else {
            NSInteger oldGroupRow = self.selectedGroup ? ([self.modelDAO.bookmarkGroups indexOfObject:self.selectedGroup] + 2) : 1;
            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldGroupRow inSection:0];
            self.selectedGroup = self.modelDAO.bookmarkGroups[indexPath.row - 2];
            [self.delegate didSetBookmarkGroup:self.selectedGroup];

            if ([indexPath isEqual:oldIndexPath]) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath, oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row > 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OBABookmarkGroup *group = self.modelDAO.bookmarkGroups[indexPath.row - 2];

        if (self.selectedGroup == group) {
            self.selectedGroup = nil;
            [self.delegate didSetBookmarkGroup:nil];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }

        [self.modelDAO removeBookmarkGroup:group];
        [self _refreshGroups];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Private

- (void)_refreshGroups {
    self.editButtonItem.enabled = (self.modelDAO.bookmarkGroups.count > 0);
}

@end

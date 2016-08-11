//
//  OBABookmarkGroupsViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarkGroupsViewController.h"
#import <OBAKit/OBAApplication.h>
#import <OBAKit/OBAModelDAO.h>
#import <OBAKit/OBABookmarkGroup.h>
#import "OBALabelFooterView.h"

@implementation OBABookmarkGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Bookmark Groups", @"");

    self.emptyDataSetTitle = NSLocalizedString(@"No Bookmark Groups", @"");
    self.emptyDataSetDescription = NSLocalizedString(@"Tap the '+' button to create one.", @"");

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addGroup)];

    self.tableView.tableFooterView = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        label.text = NSLocalizedString(@"Deleting a group does not delete its bookmarks. The bookmarks will instead be moved to the 'Bookmarks' group.", @"");
        label.numberOfLines = 0;
        label;
    });

    [self loadData];
}

#pragma mark - Accessors

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

#pragma mark - Actions

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addGroup {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Bookmark Group", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Name of Group", @"");
    }];

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBABookmarkGroup *group = [[OBABookmarkGroup alloc] initWithName:alertController.textFields[0].text];
        [self.modelDAO saveBookmarkGroup:group];
        [self loadData];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Table Data

- (void)loadData {

    NSMutableArray *rows = [NSMutableArray array];

    for (OBABookmarkGroup *group in self.modelDAO.bookmarkGroups) {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:group.name action:nil];
        [rows addObject:tableRow];
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:rows];

    self.sections = @[section];
    [self.tableView reloadData];
}


#pragma mark - UITableView Editing

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteRowAtIndexPath:indexPath tableView:tableView];
    }
}

#pragma mark - Table Row Actions (context menu thingy)

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {

    OBABaseRow *tableRow = [self rowAtIndexPath:indexPath];

    if (!tableRow.model) {
        // rows not backed by models don't get actions.
        return nil;
    }

    NSMutableArray<UITableViewRowAction *> *actions = [NSMutableArray array];

    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Delete", @"Title of delete bookmark group row action.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [self deleteRowAtIndexPath:indexPath tableView:tableView];
    }];
    [actions addObject:delete];

    if (tableRow.editAction) {
        UITableViewRowAction *edit = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Edit", @"Title of edit bookmark/group row action.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            tableRow.editAction();
        }];
        [actions addObject:edit];
    }
    return actions;
}

#pragma mark - Moving Table Cells

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    OBABaseRow *tableRow = [self rowAtIndexPath:sourceIndexPath];
    OBABookmarkGroup *group = tableRow.model;
    [self.modelDAO moveBookmarkGroup:group toIndex:destinationIndexPath.section];
}

#pragma mark - Table Row Deletion

- (void)deleteRowAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView {
    OBATableSection *tableSection = self.sections[indexPath.section];
    OBATableRow *tableRow = tableSection.rows[indexPath.row];

    NSMutableArray *deletedRows = [NSMutableArray new];

    NSMutableArray *rows = [NSMutableArray arrayWithArray:tableSection.rows];
    [rows removeObjectAtIndex:indexPath.row];
    tableSection.rows = rows;

    [deletedRows addObject:indexPath];

    if (tableRow.deleteModel) {
        tableRow.deleteModel();
    }

    [tableView deleteRowsAtIndexPaths:deletedRows withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end

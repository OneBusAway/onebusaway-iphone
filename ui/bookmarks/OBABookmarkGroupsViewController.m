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
#import <Masonry/Masonry.h>
#import "OBALabelFooterView.h"
#import "UILabel+OBAAdditions.h"
#import "OBATheme.h"
#import "OBATableFooterLabelView.h"

@implementation OBABookmarkGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Bookmark Groups", @"");

    self.tableView.allowsSelectionDuringEditing = YES;

    self.emptyDataSetTitle = NSLocalizedString(@"No Bookmark Groups", @"");
    self.emptyDataSetDescription = NSLocalizedString(@"Tap the '+' button to create one.", @"");

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addGroup)];

    self.tableView.tableFooterView = ({
        OBATableFooterLabelView *footerLabel = [[OBATableFooterLabelView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 100)];
        footerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        footerLabel.label.text = NSLocalizedString(@"Deleting a group does not delete its bookmarks. The bookmarks will instead be moved to the 'Bookmarks' group.", @"");
        [footerLabel resizeToFitText];
        footerLabel;
    });

    self.editing = YES;

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
        tableRow.model = group;
        [tableRow setEditAction:^(OBABaseRow *row) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Edit Group Name", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField * textField) {
                textField.text = group.name;
            }];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                group.name = alert.textFields.firstObject.text;
                [self.modelDAO persistGroups];
                [self loadData];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }];
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

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    OBABookmarkGroup *group = [self rowAtIndexPath:sourceIndexPath].model;
    [self.modelDAO moveBookmarkGroup:group toIndex:destinationIndexPath.row];
    [self loadData];
}

#pragma mark - Moving Table Cells

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
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

    [self.modelDAO removeBookmarkGroup:tableRow.model];

    [tableView deleteRowsAtIndexPaths:deletedRows withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end

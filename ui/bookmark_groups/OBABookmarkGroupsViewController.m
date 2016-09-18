//
//  OBABookmarkGroupsViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarkGroupsViewController.h"
#import <Masonry/Masonry.h>
#import "OBALabelFooterView.h"
#import <OBAKit/OBAKit.h>

@interface OBABookmarkGroupsViewController ()
@property(nonatomic,strong) UIView *originalFooterView;
@property(nonatomic,strong) UIView *footerView;
@end

@implementation OBABookmarkGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Bookmark Groups", @"");

    self.tableView.allowsSelectionDuringEditing = YES;

    // Normally, if a table view is empty, it will still
    // display its row separators. This looks bad when you
    // want to display an 'empty data set' message. So, we
    // get around this by displaying an empty footer view
    // on the table, which 'tricks' it into not showing the
    // row separators. Unfortunately, because we have a
    // real table footer view that is, on occasion, displayed,
    // we need to make sure that gets saved for later rendering
    // when needed.
    self.originalFooterView = self.tableView.tableFooterView;

    self.emptyDataSetTitle = NSLocalizedString(@"No Bookmark Groups", @"");
    self.emptyDataSetDescription = NSLocalizedString(@"Tap the '+' button to create one.", @"");

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addGroup)];

    [self loadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self setEditing:YES animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self setEditing:NO animated:NO];
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

    [alertController addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:OBAStrings.save style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
            [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.save style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                group.name = alert.textFields.firstObject.text;
                [self.modelDAO persistGroups];
                [self loadData];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }];

        [tableRow setDeleteModel:^(OBABaseRow *row){
            [self.modelDAO removeBookmarkGroup:row.model];
        }];

        [rows addObject:tableRow];
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:rows];

    if (rows.count > 0) {
        [self showTableFooter];
    }
    else {
        [self hideTableFooter];
    }

    self.sections = @[section];
    [self.tableView reloadData];
}

#pragma mark - Table Footer

- (UIView*)footerView {
    if (!_footerView) {
        _footerView = [OBAUIBuilder footerViewWithText:NSLocalizedString(@"Deleting a group does not delete its bookmarks. Its contents will be moved to the 'Bookmarks' group.", @"") maximumWidth:CGRectGetWidth(self.tableView.frame)];
    }
    return _footerView;
}

- (void)showTableFooter {
    self.tableView.tableFooterView = self.footerView;
}

- (void)hideTableFooter {
    self.tableView.tableFooterView = self.originalFooterView;
}

#pragma mark - UITableView Editing

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteRowAtIndexPath:indexPath];
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

@end

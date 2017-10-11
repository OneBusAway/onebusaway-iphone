//
//  OBABookmarkGroupsViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarkGroupsViewController.h"
@import OBAKit;
@import Masonry;
#import "OBALabelFooterView.h"

@implementation OBABookmarkGroupsViewController {
    UIAlertAction *_saveButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"msg_bookmark_groups", @"");

    self.tableView.allowsSelectionDuringEditing = YES;

    self.emptyDataSetTitle = NSLocalizedString(@"msg_no_bookmark_groups", @"");
    self.emptyDataSetDescription = NSLocalizedString(@"msg_explanatory_add_bookmark_group", @"");

    self.tableFooterView = [self buildFooterView];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:self.enableGroupEditing ? UIBarButtonSystemItemDone : UIBarButtonSystemItemCancel
                                             target:self
                                             action:@selector(close)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addGroup)];

    [self loadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self setEditing:self.enableGroupEditing animated:YES];
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
    [self addEditGroupName:nil];
}

- (void)addEditGroupName:(OBABookmarkGroup *)group {
    NSString *title = group ? NSLocalizedString(@"msg_edit_group_name",) : NSLocalizedString(@"msg_add_bookmark_group",);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"msg_name_of_group",);
        textField.text = group.name;
        [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];

    void (^addGroup)(UIAlertAction *action) = ^(UIAlertAction *action) {
        OBABookmarkGroup *newGroup = [[OBABookmarkGroup alloc] initWithName:alertController.textFields.firstObject.text];
        [self.modelDAO saveBookmarkGroup:newGroup];
        [self loadData];
    };

    void (^editGroup)(UIAlertAction *action) = ^(UIAlertAction *action) {
        group.name = alertController.textFields.firstObject.text;
        [self.modelDAO persistGroups];
        [self loadData];
    };

    _saveButton = [UIAlertAction actionWithTitle:OBAStrings.save style:UIAlertActionStyleDefault
                                         handler:(group) ? editGroup : addGroup];

    _saveButton.enabled = (group.name.length > 0);
    [alertController addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:_saveButton];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)textFieldDidChange:(UITextField *)textField {
    if (_saveButton) {
        _saveButton.enabled = (textField.text.length > 0);
    }
}

#pragma mark - Table Data

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    OBABookmarkGroup *group = [self rowAtIndexPath:indexPath].model;

    if ([self.delegate respondsToSelector:@selector(didSetBookmarkGroup:)]) {
        [self.delegate didSetBookmarkGroup:group];
        [self close];
    }
    else if (group.bookmarkGroupType == OBABookmarkGroupTypeRegular) {
        [self addEditGroupName:group];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)loadData {

    NSMutableArray *rows = [NSMutableArray array];

    for (OBABookmarkGroup *group in self.modelDAO.bookmarkGroups) {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:group.name action:nil];
        tableRow.model = group;

        [tableRow setEditAction:^{
            [self addEditGroupName:group];
        }];

        [tableRow setDeleteModel:^(OBABaseRow *row){
            [self.modelDAO removeBookmarkGroup:row.model];
        }];

        [rows addObject:tableRow];
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:rows];

    self.sections = @[section];
    [self.tableView reloadData];
}

#pragma mark - UITableView Editing

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBABaseRow *row = [self rowAtIndexPath:indexPath];
    OBABookmarkGroup *group = [row model];

    if (group.bookmarkGroupType == OBABookmarkGroupTypeRegular) {
        return UITableViewCellEditingStyleDelete;
    }
    else {
        return UITableViewCellEditingStyleNone;
    }
}

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

#pragma mark - Private

- (UIView*)buildFooterView {
    NSString *message = self.enableGroupEditing ?
    NSLocalizedString(@"msg_explanatory_delete_group_bookmarks",) :
    NSLocalizedString(@"msg_select_or_add_to_group_bookmark",);

    return [OBAUIBuilder footerViewWithText:message maximumWidth:CGRectGetWidth(self.tableView.frame)];
}

@end

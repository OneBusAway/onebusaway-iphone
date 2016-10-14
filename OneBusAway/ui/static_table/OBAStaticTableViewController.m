//
//  OBAStaticTableViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBAStaticTableViewController.h"
@import OBAKit;
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import "OBATableCell.h"
#import "OBAViewModelRegistry.h"
#import "OBAVibrantBlurContainerView.h"

@interface OBAStaticTableViewController ()<UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@property(nonatomic,strong,readwrite) UITableView *tableView;
@property(nonatomic,strong) UIVisualEffectView *blurContainer;
@end

@implementation OBAStaticTableViewController

#pragma mark - UIViewController

- (void)loadView {
    if (self.rootViewStyle == OBARootViewStyleBlur) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        blurEffectView.frame = [UIScreen mainScreen].bounds;
        self.view = blurEffectView;
        _blurContainer = blurEffectView;
    }
    else {
        self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.frame = self.view.bounds;

    NSArray *registered = [OBAViewModelRegistry registeredClasses];

    for (Class c in registered) {
        [c registerViewsWithTableView:self.tableView];
    }

    if (self.blurContainer) {
        self.tableView.backgroundColor = [UIColor clearColor];
        [self.blurContainer.contentView addSubview:self.tableView];
    }
    else {
        [self.view addSubview:self.tableView];
    }

    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self registerKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self unregisterKeyboardNotifications];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

#pragma mark - Accessors

- (UITableView*)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

- (void)setTableFooterView:(UIView *)tableFooterView {
    if (_tableFooterView == tableFooterView) {
        return;
    }

    _tableFooterView = tableFooterView;

    if (self.isViewLoaded) {
        if (!self.tableView.emptyDataSetVisible) {
            self.tableView.tableFooterView = _tableFooterView;
        }
    }
}

#pragma mark - Public Methods

- (OBABaseRow*)rowAtIndexPath:(NSIndexPath*)indexPath {
    OBAGuard(indexPath && indexPath.section < self.sections.count) else {
        return nil;
    }

    OBATableSection *section = self.sections[indexPath.section];

    OBAGuard(indexPath.row < section.rows.count) else {
        return nil;
    }

    return section.rows[indexPath.row];
}

- (nullable NSIndexPath*)indexPathForRow:(OBABaseRow*)row {
    for (NSInteger i=0; i<self.sections.count; i++) {
        OBATableSection *section = self.sections[i];
        for (NSInteger j=0; j<section.rows.count; j++) {
            OBABaseRow *candidate = section.rows[j];

            if ([row isEqual:candidate]) {
                return [NSIndexPath indexPathForRow:j inSection:i];
            }
        }
    }

    return nil;
}

- (NSIndexPath*)indexPathForModel:(id)model {
    for (NSInteger i=0; i<self.sections.count; i++) {
        OBATableSection *section = self.sections[i];
        for (NSInteger j=0; j<section.rows.count; j++) {
            OBABaseRow *candidate = section.rows[j];

            if ([candidate.model isEqual:model]) {
                return [NSIndexPath indexPathForRow:j inSection:i];
            }
        }
    }

    return nil;
}

- (BOOL)replaceRowAtIndexPath:(NSIndexPath*)indexPath withRow:(OBABaseRow*)row {
    if (!indexPath || !row) {
        return NO;
    }

    OBATableSection *section = self.sections[indexPath.section];
    if (!section) {
        return NO;
    }

    NSMutableArray *rows = [NSMutableArray arrayWithArray:section.rows];

    if (indexPath.row < rows.count) {
        [rows replaceObjectAtIndex:indexPath.row withObject:row];
    }
    else {
        [rows addObject:row];
    }
    section.rows = [NSArray arrayWithArray:rows];

    return YES;
}

- (void)deleteRowAtIndexPath:(NSIndexPath*)indexPath {
    OBABaseRow *tableRow = [self rowAtIndexPath:indexPath];

    OBAGuard(tableRow.deleteModel) else {
        return;
    }

    OBATableSection *section = self.sections[indexPath.section];
    [section removeRowAtIndex:indexPath.row];

    tableRow.deleteModel(tableRow);

    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableView Section Headers

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    UIView *headerView = [self tableView:tableView viewForHeaderInSection:section];

    if (headerView) {
        return CGRectGetHeight(headerView.frame);
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.sections[section].headerView;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section].title;
}

#pragma mark - UITableView Section Footers

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    UIView *footerView = [self tableView:tableView viewForFooterInSection:section];

    if (footerView) {
        return CGRectGetHeight(footerView.frame);
    }
    else {
        return 0.f;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return self.sections[section].footerView;
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    OBATableSection *section = self.sections[sectionIndex];
    return section.rows.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OBABaseRow *row = [self rowAtIndexPath:indexPath];
    NSString *reuseIdentifier = [row cellReuseIdentifier];

    UITableViewCell<OBATableCell> *cell = (UITableViewCell<OBATableCell> *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

    OBAGuard([cell conformsToProtocol:@protocol(OBATableCell)]) else {
        // TODO: Can't return nil here; declaration in UITableViewDataSource is NONNULL
        return nil;
    }

    if (self.rootViewStyle == OBARootViewStyleBlur) {
        // visual effect view backgrounds require clear
        // background colored cells.
        cell.backgroundColor = [UIColor clearColor];
    }

    cell.tableRow = row;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[self rowAtIndexPath:indexPath] indentationLevel];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OBABaseRow *row = [self rowAtIndexPath:indexPath];

    if (tableView.editing && row.editAction) {
        row.editAction();
    }
    else if (!tableView.editing && row.action) {
        row.action(row);
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    OBABaseRow *row = [self rowAtIndexPath:indexPath];
    return row.rowActions.count > 0;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBABaseRow *row = [self rowAtIndexPath:indexPath];
    return row.rowActions;
}

#pragma mark - DZNEmptyDataSet

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {

    if (!self.emptyDataSetTitle) {
        return nil;
    }

    // There are some goofy circumstances, like on the bookmarks
    // controller, where the empty data set title and description
    // should be hidden even if there are no rows in the table due
    // to the toggleable row display features used on that view.
    if (self.sections.count >= 2) {
        return nil;
    }

    NSDictionary *attributes = @{NSFontAttributeName: [OBATheme titleFont],
                                 NSForegroundColorAttributeName: [OBATheme darkDisabledColor]};

    return [[NSAttributedString alloc] initWithString:self.emptyDataSetTitle attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    if (!self.emptyDataSetDescription) {
        return nil;
    }

    // There are some goofy circumstances, like on the bookmarks
    // controller, where the empty data set title and description
    // should be hidden even if there are no rows in the table due
    // to the toggleable row display features used on that view.
    if (self.sections.count >= 2) {
        return nil;
    }

    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;

    NSDictionary *attributes = @{NSFontAttributeName: [OBATheme bodyFont],
                                 NSForegroundColorAttributeName: [OBATheme lightDisabledColor],
                                 NSParagraphStyleAttributeName: paragraph};

    return [[NSAttributedString alloc] initWithString:self.emptyDataSetDescription attributes:attributes];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    // Totally arbitrary value. It just 'looks right'.
    return -44;
}

- (void)emptyDataSetWillAppear:(UIScrollView *)scrollView {
    self.tableView.tableFooterView = [UIView new];
}

- (void)emptyDataSetWillDisappear:(UIScrollView *)scrollView {
    if (self.tableFooterView) {
        self.tableView.tableFooterView = self.tableFooterView;
    }
}

#pragma mark - Keyboard Management

/**
 Adapted from http://stackoverflow.com/a/13163543
 */

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    CGSize kbSize = [aNotification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0.0, kbSize.height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification  {
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

@end

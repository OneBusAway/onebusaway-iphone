//
//  OBAStaticTableViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAStaticTableViewController.h>
#import <OBAKit/UIScrollView+EmptyDataSet.h>
#import <OBAKit/OBAViewModelRegistry.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBATableCell.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/OBAPlaceholderRow.h>
#import <OBAKit/OBAStrings.h>

@interface OBAStaticTableViewController ()<DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@property(nonatomic,strong,readwrite) UITableView *tableView;
@property(nonatomic,strong) UIVisualEffectView *blurContainer;
@end

@implementation OBAStaticTableViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        _showsLoadingPlaceholderRows = YES;
    }
    return self;
}

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

    UIView *tableParentView = nil;

    if (self.blurContainer) {
        self.tableView.backgroundColor = [UIColor clearColor];
        tableParentView = self.blurContainer.contentView;
    }
    else {
        tableParentView = self.view;
    }

    [tableParentView addSubview:self.tableView];

    // Empty Data Set

    // Totally arbitrary value. It just 'looks right'.
    self.emptyDataSetVerticalOffset = -44.f;

    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;

    // Shimmering 'Loading' Cells
    if (self.showsLoadingPlaceholderRows) {
        [self displayLoadingUI];
    }
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

        // Setting these three values to 0 works around a table view behavior
        // change in iOS 11 that causes blank section headers to show up
        // without it. See https://github.com/OneBusAway/onebusaway-iphone/issues/1171
        // for the issue and https://github.com/venmo/Static/issues/105 for my inspiration.
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;

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
    OBAGuard(indexPath) else {
        return nil;
    }

    if (indexPath.section >= self.sections.count) {
        return nil;
    }

    OBATableSection *section = self.sections[indexPath.section];

    if (indexPath.row >= section.rows.count) {
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
            if (candidate.model == model) { // Need to compare the pointers to get the correct indexPath
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

- (BOOL)deleteRowAtIndexPath:(NSIndexPath*)indexPath {
    OBABaseRow *tableRow = [self rowAtIndexPath:indexPath];

    OBAGuard(tableRow.deleteModel) else {
        return NO;
    }

    OBATableSection *section = self.sections[indexPath.section];
    [section removeRowAtIndex:indexPath.row];

    tableRow.deleteModel(tableRow);

    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    return YES;
}

- (void)insertRow:(OBABaseRow*)row atIndexPath:(NSIndexPath*)indexPath animation:(UITableViewRowAnimation)animation {
    OBAGuard(row && indexPath) else {
        return;
    }

    OBAGuard(indexPath.section < self.sections.count) else {
        return;
    }

    OBATableSection *section = self.sections[indexPath.section];
    NSMutableArray *rows = [NSMutableArray arrayWithArray:section.rows];

    [rows insertObject:row atIndex:MIN(indexPath.row, section.rows.count)];
    section.rows = [NSArray arrayWithArray:rows];

    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:animation];
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

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBABaseRow *row = [self rowAtIndexPath:indexPath];
    UISwipeActionsConfiguration *actionsConfiguration = [row.rowActions copy];

    // Add a delete action if a delete model exists.

    if (!row.deleteModel) {
        return row.rowActions;
    }

    UISwipeActionsConfiguration *configurationWithDeleteAction;

    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:OBAStrings.delete handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {

        BOOL deleteStatus = [self deleteRowAtIndexPath: indexPath];
        completionHandler(deleteStatus);
    }];

    if (actionsConfiguration) {
        NSArray<UIContextualAction*> *actions = [[actionsConfiguration actions] arrayByAddingObject:deleteAction];
        configurationWithDeleteAction = [UISwipeActionsConfiguration configurationWithActions:actions];
    } else {
        configurationWithDeleteAction = [UISwipeActionsConfiguration configurationWithActions: @[deleteAction]];
    }

    return configurationWithDeleteAction;
}

#pragma mark - Placeholder UI

- (void)displayLoadingUI {
    OBAPlaceholderRow *row1 = [[OBAPlaceholderRow alloc] init];
    OBAPlaceholderRow *row2 = [[OBAPlaceholderRow alloc] init];

    NSArray *placeholderRows = @[row1, row2];
    OBATableSection *placeholderSection = [[OBATableSection alloc] initWithTitle:nil rows:placeholderRows];
    self.sections = @[placeholderSection];

    [self.tableView reloadData];
}

- (void)hideLoadingUI {
    self.sections = @[];
    [self.tableView reloadData];
}

#pragma mark - DZNEmptyDataSet

- (void)reloadEmptyDataSet {
    [self.tableView reloadEmptyDataSet];
}

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

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return self.emptyDataSetImage;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return self.emptyDataSetVerticalOffset;
}

- (UIColor *)imageTintColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor lightGrayColor];
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

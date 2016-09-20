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

#import "OBAEditStopBookmarkViewController.h"
#import "OBATextFieldTableViewCell.h"
#import "OBAStopViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
#import <OBAKit/OBAKit.h>
#import "OneBusAway-Swift.h"

@interface OBAEditStopBookmarkViewController ()
@property(nonatomic,strong) OBABookmarkV2 *bookmark;
@property(nonatomic,strong) OBABookmarkGroup *selectedGroup;
@property(nonatomic,strong) NSHashTable *requests;
@property(nonatomic,strong) NSMutableDictionary *stops;
@property(nonatomic,strong) UITextField *textField;
@end

@implementation OBAEditStopBookmarkViewController

- (instancetype)initWithBookmark:(OBABookmarkV2 *)bookmark {
    self = [super init];

    if (self) {
        self.tableView.scrollEnabled = NO;

        _bookmark = bookmark;
        _selectedGroup = _bookmark.group;

        _requests = [NSHashTable weakObjectsHashTable];
        _stops = [[NSMutableDictionary alloc] init];

        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];

        self.navigationItem.title = NSLocalizedString(@"Edit Bookmark", @"OBABookmarkEditExisting");
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self hideEmptySeparators];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];

    NSString *stopId = _bookmark.stopId;
    [self.modelService requestStopForId:stopId completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
        OBAEntryWithReferencesV2 *entry = responseData;
        OBAStopV2 *stop = entry.entry;

        if (stop) {
            self->_stops[stop.stopId] = stop;
            NSIndexPath *path = [NSIndexPath indexPathForRow:1 inSection:0];
            NSArray *indexPaths = @[path];
            [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
}

#pragma mark - Lazy Loading

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        OBATextFieldTableViewCell *cell =  [OBATextFieldTableViewCell getOrCreateCellForTableView:tableView];
        cell.textField.text = _bookmark.name;
        self.textField = cell.textField;
        [self.textField becomeFirstResponder];
        [tableView addSubview:cell]; // make keyboard slide in/out from right.
        return cell;
    }
    else if (indexPath.row == 1) {
        UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

        NSString *stopId = self.bookmark.stopId;
        OBAStopV2 *stop = self.stops[stopId];

        if (stop) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ # %@ - %@", NSLocalizedString(@"Stop", @"stop"), @"", stop.name];
        }
        else {
            cell.textLabel.text = NSLocalizedString(@"Loading stop info...", @"!stop");
        }

        cell.textLabel.font = [OBATheme bodyFont];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.selectionStyle =  UITableViewCellSelectionStyleNone;
        return cell;
    }
    else {
        UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"BookmarkGroupCell"];
        NSString *groupName = @"None";

        if (self.selectedGroup) {
            groupName = self.selectedGroup.name;
        }

        cell.textLabel.text = [NSString stringWithFormat:@"Set Group: %@", groupName];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2) {
        OBABookmarkGroupsViewController *groups = [[OBABookmarkGroupsViewController alloc] init];
        groups.enableGroupEditing = NO;
        groups.delegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:groups];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

- (void)didSetBookmarkGroup:(OBABookmarkGroup *)group {
    self.selectedGroup = group;
}

#pragma mark - Actions

- (void)cancel:(id)sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save:(id)sender {
    [self.view endEditing:YES];

    self.bookmark.name = self.textField.text;

    if (![self.bookmark isValidModel]) {
        [AlertPresenter showWarning:NSLocalizedString(@"Can't Create Bookmark", @"Title of the alert shown when a bookmark can't be created") body:NSLocalizedString(@"Bookmarks must have a name. Please add a name and then try again.", @"Body of the alert shown when a bookmark can't be created.")];
        return;
    }

    if (!self.bookmark.group && !self.selectedGroup) {
        [self.modelDAO saveBookmark:self.bookmark];
    }
    else {
        [self.modelDAO moveBookmark:self.bookmark toGroup:self.selectedGroup];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

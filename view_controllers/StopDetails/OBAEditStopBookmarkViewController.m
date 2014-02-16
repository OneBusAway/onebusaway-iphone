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
#import "OBALogger.h"
#import "OBATextFieldTableViewCell.h"
#import "OBARoute.h"
#import "OBAStopViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "OBABookmarkGroup.h"
#import "OBAEditStopBookmarkGroupViewController.h"

@implementation OBAEditStopBookmarkViewController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate bookmark:(OBABookmarkV2*)bookmark editType:(OBABookmarkEditType)editType {

    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.tableView.scrollEnabled = NO;

        _appDelegate = appDelegate;
        _bookmark = bookmark;
        _selectedGroup = bookmark.group;
        _editType = editType;

        _requests = [[NSMutableArray alloc] initWithCapacity:[_bookmark.stopIds count]];
        _stops = [[NSMutableDictionary alloc] init];

        UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelButton:)];
        [self.navigationItem setLeftBarButtonItem:cancelButton];
        
        UIBarButtonItem * saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSaveButton:)];
        [self.navigationItem setRightBarButtonItem:saveButton];
        
        switch(_editType) {
            case OBABookmarkEditNew:
                self.navigationItem.title = NSLocalizedString(@"Add Bookmark",@"OBABookmarkEditNew");
                break;
            case OBABookmarkEditExisting:
                self.navigationItem.title = NSLocalizedString(@"Edit Bookmark",@"OBABookmarkEditExisting");
                break;
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self hideEmptySeparators];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    
    OBAModelService * service = _appDelegate.modelService;
    NSArray * stopIds = _bookmark.stopIds;
    for( NSUInteger i=0; i<[stopIds count]; i++) {
        NSString * stopId = stopIds[i];
        NSNumber * index = [NSNumber numberWithInt:i];
        id<OBAModelServiceRequest> request = [service requestStopForId:stopId withDelegate:self withContext:index];
        [_requests addObject:request];
    }

    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark OBAModelServiceRequest

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    
    OBAEntryWithReferencesV2 * entry = obj;
    OBAStopV2 * stop = entry.entry;
    
    NSNumber * num = context;
    NSUInteger index = [num intValue];
    
    if( stop ) {
        _stops[stop.stopId] = stop;
        NSIndexPath * path = [NSIndexPath indexPathForRow:index+1 inSection:0];
        NSArray * indexPaths = @[path];
        [self.tableView  reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [_requests removeObject:request];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if( indexPath.row == 0 ) {
        OBATextFieldTableViewCell * cell =  [OBATextFieldTableViewCell getOrCreateCellForTableView:tableView];
        cell.textField.text = _bookmark.name;
        _textField = cell.textField;
        [_textField becomeFirstResponder];
        [tableView addSubview:cell]; // make keyboard slide in/out from right.
        return cell;
    }
    else if ( indexPath.row == 1 ){
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        
        NSString * stopId = (_bookmark.stopIds)[indexPath.row-1];
        OBAStopV2 * stop = _stops[stopId];
        if( stop )
            cell.textLabel.text = [NSString stringWithFormat:@"%@ # %@ - %@",NSLocalizedString(@"Stop",@"stop"),stop.code,stop.name];
        else
            cell.textLabel.text = NSLocalizedString(@"Loading stop info...",@"!stop");
        
        cell.textLabel.font = [UIFont systemFontOfSize: 12];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.selectionStyle =  UITableViewCellSelectionStyleNone;
        return cell;
    }
    else {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"BookmarkGroupCell"];
        NSString *groupName = @"None";
        if (_selectedGroup) {
            groupName = _selectedGroup.name;
        }
        cell.textLabel.text = [NSString stringWithFormat:@"Set Group: %@", groupName];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2) {
        OBAEditStopBookmarkGroupViewController *groupVC = [[OBAEditStopBookmarkGroupViewController alloc] initWithAppDelegate:_appDelegate selectedBookmarkGroup:_selectedGroup];
        groupVC.delegate = self;
        [self.navigationController pushViewController:groupVC animated:YES];
    }
}

- (void)didSetBookmarkGroup:(OBABookmarkGroup *)group {
    _selectedGroup = group;
}

- (IBAction) onCancelButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) onSaveButton:(id)sender {
        
    OBAModelDAO * dao = _appDelegate.modelDao;
    
    _bookmark.name = _textField.text;
    
    if (!_bookmark.group && !_selectedGroup) {
        if (_editType == OBABookmarkEditNew) {
            [dao addNewBookmark:_bookmark];
        }
        [dao saveExistingBookmark:_bookmark];
    } else {
        [dao moveBookmark:_bookmark toGroup:_selectedGroup];
    }

    // pop to stop view controller are saving settings
    BOOL foundStopViewController = NO;
    for (UIViewController* viewController in [self.navigationController viewControllers]) {
        if ([viewController isKindOfClass:[OBAStopViewController class]]) {
            [self.navigationController popToViewController:viewController animated:YES];
            foundStopViewController = YES;
            break;
        }
    }
    
    if (!foundStopViewController)
        [self.navigationController popViewControllerAnimated:YES];
}

@end


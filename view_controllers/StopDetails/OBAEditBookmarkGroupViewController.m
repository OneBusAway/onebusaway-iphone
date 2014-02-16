//
//  OBAEditBookmarkGroupViewController.m
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 28/12/2013.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBAEditBookmarkGroupViewController.h"
#import "OBATextFieldTableViewCell.h"
#import "OBAApplicationDelegate.h"
#import "OBABookmarkGroup.h"
#import "OBAModelDAO.h"

@interface OBAEditBookmarkGroupViewController ()
{
    OBAApplicationDelegate *_appDelegate;
    OBABookmarkGroup *_bookmarkGroup;
    UITextField *_textField;
}
@end

@implementation OBAEditBookmarkGroupViewController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate bookmarkGroup:(OBABookmarkGroup*)bookmarkGroup editType:(OBABookmarkGroupEditType)editType {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _appDelegate = appDelegate;
        _bookmarkGroup = bookmarkGroup;
        
        UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelButton:)];
        [self.navigationItem setLeftBarButtonItem:cancelButton];
        
        UIBarButtonItem * saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSaveButton:)];
        [self.navigationItem setRightBarButtonItem:saveButton];
        
        switch (editType) {
            case OBABookmarkGroupEditNew:
                self.navigationItem.title = NSLocalizedString(@"Add Bookmark Group", @"OBABookmarkGroupEditNew");
                break;
                
            case OBABookmarkGroupEditExisting:
                self.navigationItem.title = NSLocalizedString(@"Edit Bookmark Group", @"OBABookmarkGroupEditExisting");
                break;
        }
    }
    return self;
}

- (void)onCancelButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onSaveButton:(id)sender {
    OBAModelDAO *dao = _appDelegate.modelDao;
    _bookmarkGroup.name = _textField.text;
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                  action:@"edit_field"
                                                   label:@"Edited Bookmark"
                                                   value:nil] build]];
    [dao addOrSaveBookmarkGroup:_bookmarkGroup];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OBATextFieldTableViewCell *cell = [OBATextFieldTableViewCell getOrCreateCellForTableView:tableView];
    [cell.textField becomeFirstResponder];
    _textField = cell.textField;
    _textField.text = _bookmarkGroup.name;
    [tableView addSubview:cell];
    return cell;
}


@end

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
#import "OBAUITableViewCell.h"
#import "OBATextFieldTableViewCell.h"
#import "OBARoute.h"


static NSString * kOBABookmarkParameter = @"OBABookmarkParameter";
static NSString * kOBAEditTypeParameter = @"OBAEditTypeParameter";

@implementation OBAEditStopBookmarkViewController

+ (NSDictionary*) getParametersForBookmark:(OBABookmark*)bookmark editType:(OBABookmarkEditType)editType {
	NSMutableDictionary * params = [NSMutableDictionary dictionary];
	[params setObject:bookmark forKey:kOBABookmarkParameter];
	[params setObject:[NSNumber numberWithInt:editType] forKey:kOBAEditTypeParameter];
	return params;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext bookmark:(OBABookmark*)bookmark editType:(OBABookmarkEditType)editType {

    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		self.tableView.scrollEnabled = FALSE;

		_appContext = [appContext retain];
		_bookmark = [bookmark retain];
		_editType = editType;

		UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelButton:)];
		[self.navigationItem setLeftBarButtonItem:cancelButton];
		[cancelButton release];
		
		UIBarButtonItem * saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSaveButton:)];
		[self.navigationItem setRightBarButtonItem:saveButton];
		[saveButton release];
		
		switch(_editType) {
			case OBABookmarkEditNew:
				self.navigationItem.title = @"Add Bookmark";
				break;
			case OBABookmarkEditExisting:
				self.navigationItem.title = @"Edit Bookmark";
				break;
		}
    }
	
    return self;
}

- (void)dealloc {
	[_appContext release];
	[_bookmark release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 2;
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
	else {
		OBAStop * stop = _bookmark.stop;
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = [NSString stringWithFormat:@"%@ - Stop # %@",stop.name,stop.code];
		cell.textLabel.font = [UIFont systemFontOfSize: 12];
		cell.textLabel.textColor = [UIColor grayColor];
		cell.selectionStyle =  UITableViewCellSelectionStyleNone;
		return cell;
	}
}

- (IBAction) onCancelButton:(id)sender {

	// Undo any changes made
	[_appContext.modelDao rollback];
	
	[self.navigationController popViewControllerAnimated:TRUE];
}

- (IBAction) onSaveButton:(id)sender {
		
	OBAModelDAO * dao = _appContext.modelDao;
	NSError * error = nil;
	
	_bookmark.name = _textField.text;
	
	switch (_editType ) {
		case OBABookmarkEditNew:
			[dao addNewBookmark:_bookmark error:&error];
			break;
		case OBABookmarkEditExisting:
			[dao saveExistingBookmark:_bookmark error:&error];
			break;
	}

	if( error )
		OBALogSevereWithError(error,@"Error saving bookmark: name=%@ stop=%@",_bookmark.name,_bookmark.stop.stopId);

	[self.navigationController popViewControllerAnimated:TRUE];
}

@end


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

#import "OBASearchViewController.h"
#import "OBAUIKit.h"
#import "OBASearchTableViewCell.h"
#import "OBASearchController.h"

#include "OBASearchResultsMapViewController.h"


const static int kSearchTableViewCellHeight = 127;
static NSString * kOBASearchViewType = @"kOBASearchViewType";
static NSString * kOBASearchValue = @"kOBASearchValue";

@interface OBASearchViewController (Private)
- (void) handleRouteSearch:(NSString*)query;
- (void) handleAddressSearch:(NSString*)query;
- (void) handleStopSearch:(NSString*)query;
@end

@implementation OBASearchViewController

@synthesize appContext = _appContext;
@synthesize searchTypeControl = _searchTypeControl;
@synthesize searchField = _searchField;
@synthesize cancelButton = _cancelButton;

+ (NSDictionary*) getParametersForSearchType:(OBASearchViewType)searchType {
	return [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:searchType] forKey:kOBASearchViewType];
}

- (void)dealloc {
	[_appContext release];
	[_navigationTarget release];
	
	[_searchTypeControl release];
	[_searchField release];
	[_searchCell release];
	[_cancelButton release];
	
	[_routeSavedValue release];
	[_addressSavedValue release];
	[_stopIdSavedValue release];
	
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_currentSearchType = OBASearchViewTypeByRoute;
	_navigationTarget = [[OBANavigationTarget alloc] initWithTarget:OBANavigationTargetTypeSearch];
	
	self.navigationItem.rightBarButtonItem = nil;
	
	NSArray * nib1 = [[NSBundle mainBundle] loadNibNamed:@"OBASearchTableViewCell" owner:self options:nil];
	_searchCell = [[nib1 objectAtIndex:0] retain];
	
	switch (_currentSearchType) {
		case OBASearchViewTypeByRoute:
			_searchTypeControl.selectedSegmentIndex = 0;
			[_searchField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
			break;
		case OBASearchViewTypeByAddress:
			_searchTypeControl.selectedSegmentIndex = 1;
			[_searchField setKeyboardType:UIKeyboardTypeDefault];
			break;
		case OBASearchViewTypeByStop:
			_searchTypeControl.selectedSegmentIndex = 2;
			[_searchField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
			break;
	}
	
	NSString * searchValue = [_navigationTarget parameterForKey:kOBASearchValue];
	if( searchValue )
		_searchField.text = searchValue;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	const BOOL autoDisplayKeyboard = NO;
	if (autoDisplayKeyboard)
		[_searchField becomeFirstResponder];
	
	OBALocationManager * lm = _appContext.locationManager;
	[lm startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	OBALocationManager * lm = _appContext.locationManager;
	[lm stopUpdatingLocation];
    
    // hide keyboard
    [_searchField resignFirstResponder];
}	

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kSearchTableViewCellHeight;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return _searchCell;
}

- (IBAction)onSearchTypeButton:(id)sender {
	switch(_currentSearchType) {
		case OBASearchViewTypeByRoute:
			_routeSavedValue = [_searchField.text retain];
			break;
		case OBASearchViewTypeByAddress:
			_addressSavedValue = [_searchField.text retain];
			break;
		case OBASearchViewTypeByStop:
			_stopIdSavedValue = [_searchField.text retain];
			break;
	}
	
	int index = [sender selectedSegmentIndex];
	NSString * savedValue = nil;
	switch(index) {
		case 0:
			[_searchField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
			_searchField.placeholder = @"Search by route";
			_currentSearchType = OBASearchViewTypeByRoute;
			savedValue = _routeSavedValue;
			break;
            
		case 1:
			[_searchField setKeyboardType:UIKeyboardTypeDefault];
			_searchField.placeholder = @"Search by address";
			_currentSearchType = OBASearchViewTypeByAddress;
			savedValue = _addressSavedValue;
			break;
	
        case 2:
			[_searchField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
			_searchField.placeholder = @"Search by stop #";
			_currentSearchType = OBASearchViewTypeByStop;
			savedValue = _stopIdSavedValue;
			break;
		
        default:
			NSLog(@"unknown search type index");
			break;
	}

	// refresh keyboard type if it's up
	if([_searchField isFirstResponder]) {
		[_searchField resignFirstResponder];
		[_searchField becomeFirstResponder];
	}
	
	if(savedValue && [savedValue length] > 0)
		_searchField.text = savedValue;
	else
		_searchField.text = @"";
}

- (IBAction) onCancelButton:(id)sender {
	[_searchField resignFirstResponder];
	self.navigationItem.rightBarButtonItem = nil;
}

#pragma mark UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.navigationItem.rightBarButtonItem = _cancelButton;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	self.navigationItem.rightBarButtonItem = nil;
	
	[_navigationTarget setParameter:textField.text forKey:kOBASearchValue];
	
	switch (_currentSearchType) {
		case OBASearchViewTypeByRoute:
			[self handleRouteSearch:textField.text];
			break;
            
		case OBASearchViewTypeByStop:
			[self handleStopSearch:textField.text];
			break;
	
        case OBASearchViewTypeByAddress:
			[self handleAddressSearch:textField.text];
			break;
		
        default:
			break;
	}
	return YES;	
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return _navigationTarget;
}

@end


@implementation OBASearchViewController (Private)

- (void)handleRouteSearch:(NSString*)query {
	OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchRoute:query];
	[_appContext navigateToTarget:target];
}

- (void)handleAddressSearch:(NSString*)query {
	OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchAddress:query];
	[_appContext navigateToTarget:target];
}

- (void)handleStopSearch:(NSString*)query {
	OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchStopCode:query];
	[_appContext navigateToTarget:target];
}

@end

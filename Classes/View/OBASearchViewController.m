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


const static int kSearchTableViewCellHeight = 168;
static NSString * kOBASearchType = @"kOBASearchType";
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

+ (NSDictionary*) getParametersForSearchType:(OBASearchType)searchType {
	return [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:searchType] forKey:kOBASearchType];
}

- (void)dealloc {

	[_appContext release];
	[_navigationTarget release];
	
	[_searchTypeControl release];
	[_searchField release];
	[_searchCell release];
	
	[_routeSavedValue release];
	[_addressSavedValue release];
	[_stopIdSavedValue release];
	
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_currentSearchType = OBASearchTypeByRoute;
	_navigationTarget = [[OBANavigationTarget alloc] initWithTarget:OBANavigationTargetTypeSearch];
	
	NSArray * nib1 = [[NSBundle mainBundle] loadNibNamed:@"OBASearchTableViewCell" owner:self options:nil];
	_searchCell = [[nib1 objectAtIndex:0] retain];
	
	switch (_currentSearchType) {
		case OBASearchTypeByRoute:
			_searchTypeControl.selectedSegmentIndex = 0;
			break;
		case OBASearchTypeByAddress:
			_searchTypeControl.selectedSegmentIndex = 1;
			break;
		case OBASearchTypeByStop:
			_searchTypeControl.selectedSegmentIndex = 2;
			break;
	}
	
	NSString * searchValue = [_navigationTarget parameterForKey:kOBASearchValue];
	if( searchValue )
		_searchField.text = searchValue;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[_searchField becomeFirstResponder];
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
		case OBASearchTypeByRoute:
			_routeSavedValue = [_searchField.text retain];
			break;
		case OBASearchTypeByAddress:
			_addressSavedValue = [_searchField.text retain];
			break;
		case OBASearchTypeByStop:
			_stopIdSavedValue = [_searchField.text retain];
			break;
	}
	
	int index = [sender selectedSegmentIndex];
	NSString * savedValue = nil;
	switch(index) {
		case 0:
			self.searchField.placeholder = @"Search By Route";
			_currentSearchType = OBASearchTypeByRoute;
			savedValue = _routeSavedValue;
			break;
		case 1:
			self.searchField.placeholder = @"Search By Address";
			_currentSearchType = OBASearchTypeByAddress;
			savedValue = _addressSavedValue;
			break;
		case 2:
			self.searchField.placeholder = @"Search By Stop #";
			_currentSearchType = OBASearchTypeByStop;
			savedValue = _stopIdSavedValue;
			break;
		default:
			NSLog(@"unknown search type index");
	}
	
	if( savedValue && [savedValue length] > 0)
		_searchField.text = savedValue;
	else
		_searchField.text = @"";
}

- (IBAction) onCancelButton:(id)sender {
	[_searchField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	[_navigationTarget setParameter:textField.text forKey:kOBASearchValue];
	
	switch (_currentSearchType) {
		case OBASearchTypeByRoute:
			[self handleRouteSearch:textField.text];
			break;
		case OBASearchTypeByStop:
			[self handleStopSearch:textField.text];
			break;
		case OBASearchTypeByAddress:
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

- (void) handleRouteSearch:(NSString*)query {
	OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchRoute:query];
	[_appContext navigateToTarget:target];
}

- (void) handleAddressSearch:(NSString*)query {
	OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchAddress:query];
	[_appContext navigateToTarget:target];
}

- (void) handleStopSearch:(NSString*)query {
	OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchStopCode:query];
	[_appContext navigateToTarget:target];
}

@end



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

#import "OBANavigationTargetAware.h"
#import "OBAApplicationContext.h"
#import "OBASearchTableViewCell.h"


typedef enum {
	OBASearchViewTypeByStop, OBASearchViewTypeByRoute, OBASearchViewTypeByAddress
} OBASearchViewType;


@interface OBASearchViewController : UITableViewController <OBANavigationTargetAware,UITextFieldDelegate> {
	OBAApplicationContext * _appContext;	
	OBASearchViewType _currentSearchType;
	OBANavigationTarget * _navigationTarget;

	UISegmentedControl * _searchTypeControl;
	UITextField * _searchField;
	OBASearchTableViewCell * _searchCell;
	UIBarButtonItem * _cancelButton;
	
	NSString * _routeSavedValue;
	NSString * _addressSavedValue;
	NSString * _stopIdSavedValue;
}

@property (nonatomic,retain) IBOutlet OBAApplicationContext * appContext;
@property (nonatomic,retain) IBOutlet UISegmentedControl * searchTypeControl;
@property (nonatomic,retain) IBOutlet UITextField * searchField;
@property (nonatomic,retain) IBOutlet UIBarButtonItem * cancelButton;

+ (NSDictionary*) getParametersForSearchType:(OBASearchViewType)searchType;

- (IBAction) onSearchTypeButton:(id)sender;
- (IBAction) onCancelButton:(id)sender;

@end

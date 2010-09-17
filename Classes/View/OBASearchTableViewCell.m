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

#import "OBASearchTableViewCell.h"

@implementation OBASearchTableViewCell

@synthesize searchTypes;
@synthesize searchField;
@synthesize cancelButton;

- (void) didMoveToSuperview {
	if( ! self.searchField.leftView ) {

		UIImage *leftImage = [ UIImage imageNamed: @"TextBox-MagnifyingGlass.png" ];
		UIImageView * leftImageView = [[UIImageView alloc] initWithImage:leftImage];
		self.searchField.leftView = leftImageView;
		self.searchField.leftViewMode = UITextFieldViewModeAlways;
		
		self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;		
	}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    [super dealloc];
}


@end

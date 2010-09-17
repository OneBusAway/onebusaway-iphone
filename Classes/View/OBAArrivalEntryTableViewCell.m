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

#import "OBAArrivalEntryTableViewCell.h"


@implementation OBAArrivalEntryTableViewCell

@synthesize routeLabel;
@synthesize destinationLabel;
@synthesize timeLabel;
@synthesize minutesLabel;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        // Initialization code
    }
    return self;
}

+ (OBAArrivalEntryTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {

	static NSString *cellId = @"OBAArrivalEntryTableViewCell";
	
	// Try to retrieve from the table view a now-unused cell with the given identifier
	OBAArrivalEntryTableViewCell *cell = (OBAArrivalEntryTableViewCell *) [tableView dequeueReusableCellWithIdentifier:cellId];
	
	// If no cell is available, create a new one using the given identifier
	if (cell == nil) {
		NSArray * nib = [[NSBundle mainBundle] loadNibNamed:cellId owner:self options:nil];
		cell = [nib objectAtIndex:0];
	}
	
	return cell;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}


@end

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

#import "OBAStopTableViewCell.h"



@implementation OBAStopTableViewCell

@synthesize mainLabel;
@synthesize subLabel;

+ (OBAStopTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {

	static NSString * kCellId = @"OBAStopTableViewCell";
	
	OBAStopTableViewCell * cell = (OBAStopTableViewCell *) [tableView dequeueReusableCellWithIdentifier:kCellId];
	
	if (cell == nil) {
		NSArray * nib = [[NSBundle mainBundle] loadNibNamed:kCellId owner:self options:nil];
		cell = [nib objectAtIndex:0];
	}	
	
	return cell;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setStop:(OBAStop*)stop {
	mainLabel.text = stop.name;
	subLabel.text = [NSString stringWithFormat:@"Stop # %@",stop.code];
}


- (void)dealloc {
    [super dealloc];
}


@end

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

@synthesize mainLabel = _mainLabel;
@synthesize subLabel = _subLabel;

+ (OBAStopTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {

	static NSString * kCellId = @"OBAStopTableViewCell";
	
	OBAStopTableViewCell * cell = (OBAStopTableViewCell *) [tableView dequeueReusableCellWithIdentifier:kCellId];
	
	if (cell == nil) {
		NSArray * nib = [[NSBundle mainBundle] loadNibNamed:kCellId owner:self options:nil];
		cell = [nib objectAtIndex:0];
	}	
	
	return cell;
}

- (void)dealloc {
	[_mainLabel release];
	[_subLabel release];
    [super dealloc];
}

- (void) setStop:(OBAStopV2*)stop {
	_mainLabel.text = stop.name;
	if( stop.direction )
		_subLabel.text = [NSString stringWithFormat:@"Stop # %@ - %@ bound",stop.code,stop.direction];
	else
		_subLabel.text = [NSString stringWithFormat:@"Stop # %@",stop.code];
}

@end

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

#import "OBAUITableViewCell.h"


@implementation UITableViewCell (OBAConvenienceMethods)

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView cellId:(NSString*)cellId {
	
	// Try to retrieve from the table view a now-unused cell with the given identifier
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	
	// If no cell is available, create a new one using the given identifier
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellId] autorelease];
	}
	
	return cell;
}

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {
	static NSString *cellId = @"DefaultIdentifier";
	return [self getOrCreateCellForTableView:tableView cellId:cellId];
}

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView style:(UITableViewCellStyle)style {

	NSString * cellId = [NSString stringWithFormat:@"DefaultIdentifier-%d",style];
	
	// Try to retrieve from the table view a now-unused cell with the given identifier
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	
	// If no cell is available, create a new one using the given identifier
	if (cell == nil)
		cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellId] autorelease];

	return cell;
}

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView fromResource:(NSString*)resourceName {
	
	UITableViewCell * cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:resourceName];
	
	if (cell == nil) {
		NSArray * nib = [[NSBundle mainBundle] loadNibNamed:resourceName owner:self options:nil];
		cell = [nib objectAtIndex:0];
	}
	
	return cell;
}

@end

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

#import "OBAActivityAnnotationViewController.h"
#import "OBAUITableViewCell.h"


@implementation OBAActivityAnnotationViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
	if( self = [super initWithStyle:UITableViewStyleGrouped] ) {
		_appContext = [appContext retain];
		
		_actionKeys = [[NSArray alloc] initWithObjects:@"stopped",@"walk",@"bike",@"car",@"bus",@"train",@"waiting",nil];
		
		NSMutableDictionary * actions = [[NSMutableDictionary alloc] init];
		
		[actions setObject:@"Stopped" forKey:@"stopped"];
		[actions setObject:@"Walking" forKey:@"walk"];
		[actions setObject:@"Bicycling" forKey:@"bike"];
		[actions setObject:@"In a Car" forKey:@"car"];
		[actions setObject:@"On a Bus" forKey:@"bus"];
		[actions setObject:@"On a Train" forKey:@"train"];
		[actions setObject:@"Waiting" forKey:@"waiting"];
		
		_actionLabels = [actions retain];
		
		[actions release];
	}
	return self;
}

- (void)dealloc {
	[_appContext release];
	[_actionKeys release];
	[_actionLabels release];
    [super dealloc];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_actionKeys count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSString * actionKey = [_actionKeys objectAtIndex:indexPath.row];
	NSString * actionLabel = [_actionLabels objectForKey:actionKey];
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.text = actionLabel;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString * actionKey = [_actionKeys objectAtIndex:indexPath.row];
	[_appContext.activityListeners annotationWithLabel:actionKey];
	[self.navigationController popViewControllerAnimated:TRUE];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeActivityAnnotation];
}

@end


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

#import "OBAContactUsViewController.h"
#import "OBAUITableViewCell.h"

@implementation OBAContactUsViewController

@synthesize appContext = _appContext;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [appContext retain];
	}
    return self;
}

- (void) dealloc {
	[_appContext release];
	[super dealloc];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return @"Check us on Twitter for the latest service updates:";
		case 1:
			return @"Send us feedback over email:";
		case 2:
			return @"Let us know about a bug at our Issue Tracker:";
		default:
			return nil;
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	switch( indexPath.section ) {
		case 0:
			cell.textLabel.text = @"http://twitter.com/onebusaway";
			break;
		case 1:
			cell.textLabel.text = @"contact@onebusaway.org";
			break;
		case 2:
			cell.textLabel.text = @"OneBusAway Issue Tracker";
			break;
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch(indexPath.section) {
		case 0: {
			NSString *url = [NSString stringWithString: @"http://twitter.com/onebusaway"];
			[[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
			break;
			
		}
		case 1: {
			NSString *url = [NSString stringWithString: @"mailto:contact@onebusaway.org"];
			[[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
			break;		
		}
		case 2: {
			NSString *url = [NSString stringWithString: @"http://code.google.com/p/onebusaway-iphone/issues/list"];
			[[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
			break;
		}
			
	}
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeContactUs];
}

@end


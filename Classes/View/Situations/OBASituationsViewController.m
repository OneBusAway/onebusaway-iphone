//
//  OBASituationsViewController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 11/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OBASituationsViewController.h"
#import "OBAUITableViewCell.h"
#import "OBASituationV2.h"
#import "OBASituationViewController.h"


@implementation OBASituationsViewController


#pragma mark -
#pragma mark Initialization

@synthesize args;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext situations:(NSArray*)situations {
	
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [appContext retain];
		_situations = [situations retain];
		self.navigationItem.title = @"Service Alerts";
	}
	
	return self;
}

- (void)dealloc {
	[_appContext release];
	[_situations release];
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int count = [_situations count];
	if( count == 0 )
		count = 1;
	return count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if( [_situations count] == 0 ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"No active service alerts";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		return cell;			
	}
	
	OBASituationV2 * situation = [_situations objectAtIndex:indexPath.row];
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.text = situation.summary;
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if( [_situations count] > 0) {
		OBASituationV2 * situation = [_situations objectAtIndex:indexPath.row];
		OBASituationViewController * vc = [[OBASituationViewController alloc] initWithApplicationContext:_appContext situation:situation];
		vc.args = self.args;
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
}

@end

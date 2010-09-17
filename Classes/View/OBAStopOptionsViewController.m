//
//  OBAStopOptionsViewController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 8/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OBAStopOptionsViewController.h"
#import "OBAUITableViewCell.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBAEditStopPreferencesViewController.h"


@implementation OBAStopOptionsViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stop:(OBAStopV2*)stop {
	if( self = [super initWithStyle:UITableViewStyleGrouped] ) {
		self.tableView.scrollEnabled = NO;
		_appContext = [appContext retain];
		_stop = [stop retain];
	}
	return self;
}

- (void)dealloc {
	[_appContext release];
	[_stop release];
    [super dealloc];
}

	   
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	if( indexPath.row == 0 )
		cell.textLabel.text = @"Add a bookmark";
	else if( indexPath.row == 1 )
		cell.textLabel.text = @"Filter & sort results";
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if( ! _stop )
		return;
	
	switch(indexPath.row) {
		case 0: {
			OBABookmarkV2 * bookmark = [_appContext.modelDao createTransientBookmark:_stop];
			OBAEditStopBookmarkViewController * vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationContext:_appContext bookmark:bookmark editType:OBABookmarkEditNew];
			[self.navigationController pushViewController:vc animated:YES];
            [vc release];
			break;
		}
		case 1: {
			OBAEditStopPreferencesViewController * vc = [[OBAEditStopPreferencesViewController alloc] initWithApplicationContext:_appContext stop:_stop];
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
			break;
		}
	}
}

@end


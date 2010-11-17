//
//  OBASituationViewController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 11/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OBASituationViewController.h"
#import "OBAUITableViewCell.h"
#import "OBASituationConsequenceV2.h"
#import "OBADiversionViewController.h"


typedef enum {
	OBASectionTypeNone,
	OBASectionTypeTitle,
	OBASectionTypeDetails,
	OBASectionTypeDiversion
} OBASectionType;


@interface OBASituationViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell*) tableView:(UITableView*)tableView titleCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView detailsCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView diversionCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void) didSelectDiversionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end


@implementation OBASituationViewController


#pragma mark -
#pragma mark Initialization

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext situation:(OBASituationV2*)situation {
	
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [appContext retain];
		_situation = [situation retain];
		
		NSString * diversionPath = nil;
		
		NSArray * consequences = _situation.consequences;
		for( OBASituationConsequenceV2 * consequence in consequences ) {
			if( consequence.diversionPath )
				diversionPath = consequence.diversionPath;
		}
		
		if( diversionPath )
			_diversionPath = [diversionPath retain];
	}
	
	return self;
}

- (void)dealloc {
	[_appContext release];
	[_situation release];
	[_diversionPath release];
    [super dealloc];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	int count = 2;

	if(_diversionPath)
		count++;

	return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeTitle:
			return 1;
		case OBASectionTypeDetails:
			return 1;
		case OBASectionTypeDiversion:
			return 1;
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeTitle:
			return [self tableView:tableView titleCellForRowAtIndexPath:indexPath];
		case OBASectionTypeDetails:
			return [self tableView:tableView detailsCellForRowAtIndexPath:indexPath];
		case OBASectionTypeDiversion:
			return [self tableView:tableView diversionCellForRowAtIndexPath:indexPath];
		default:
			return nil;
	}
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeDiversion:
			[self didSelectDiversionRowAtIndexPath:indexPath tableView:tableView];
	}
}

@end


@implementation OBASituationViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {

	int offset = 0;
	
	if( section == offset )
		return OBASectionTypeTitle;
	offset++;
	
	if( section == offset )
		return OBASectionTypeDetails;
	offset++;
	
	if( _diversionPath ) {
		if( section == offset )
			return OBASectionTypeDiversion;
		offset++;		
	}
	
	return OBASectionTypeNone;	
}

- (UITableViewCell*) tableView:(UITableView*)tableView titleCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.text = _situation.summary;
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	return cell;	
}

- (UITableViewCell*) tableView:(UITableView*)tableView detailsCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.text = _situation.description;
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	return cell;	
}

- (UITableViewCell*) tableView:(UITableView*)tableView diversionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.text = @"Show Reroute";
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (void) didSelectDiversionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	OBADiversionViewController * vc = [OBADiversionViewController loadFromNibWithAppContext:_appContext];
	vc.diversionPath = _diversionPath;
	[self.navigationController pushViewController:vc animated:TRUE];
}

@end



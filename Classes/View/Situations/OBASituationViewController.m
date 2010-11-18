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
#import "OBATextEditViewController.h"
#import "OBAModelDAO.h"


typedef enum {
	OBASectionTypeNone,
	OBASectionTypeTitle,
	OBASectionTypeDetails,
	OBASectionTypeMarkAsRead
} OBASectionType;


@interface OBASituationViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell*) tableView:(UITableView*)tableView titleCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView detailsCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView markAsReadCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void) didSelectDetailsRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void) didSelectMarkAsReadRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

- (NSString*) getDetails;

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

		// Mark the situation as visited
		OBAModelDAO * modelDao = _appContext.modelDao;
		[modelDao setVisited:TRUE forSituationWithId:_situation.situationId];
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
	
	int count = 3;

	if(_diversionPath)
		count++;

	return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeDetails:
			return @"Details:";
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeTitle:
			return 1;
		case OBASectionTypeDetails: {
			if( _diversionPath )
				return 2;
			return 1;
		}
		case OBASectionTypeMarkAsRead:
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
		case OBASectionTypeMarkAsRead:
			return [self tableView:tableView markAsReadCellForRowAtIndexPath:indexPath];
		default:
			return nil;
	}
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeDetails:
			[self didSelectDetailsRowAtIndexPath:indexPath tableView:tableView];
			break;
		case OBASectionTypeMarkAsRead:
			[self didSelectMarkAsReadRowAtIndexPath:indexPath tableView:tableView];
			break;
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
	
	if( section == offset )
		return OBASectionTypeMarkAsRead;
	offset++;
	
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
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	
	if( indexPath.row == 0 ) {
		cell.textLabel.text = [self getDetails];
	}
	else if ( indexPath.row == 1 && _diversionPath ) {
		cell.textLabel.text = @"Show reroute";
	}
	
	return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView markAsReadCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBAModelDAO * modelDao = _appContext.modelDao;
	BOOL isRead = [modelDao isVisitedSituationWithId:_situation.situationId];

	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.text = isRead ? @"Mark as Unread" : @"Mark as Read";
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryNone;
	return cell;
}

- (void) didSelectDetailsRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {

	if( indexPath.row == 0 ) {
		[OBATextEditViewController pushOntoViewController:self withText:[self getDetails] withTitle:@"Details" readOnly:TRUE];
	}
	else if( indexPath.row == 1 && _diversionPath ) {
		OBADiversionViewController * vc = [OBADiversionViewController loadFromNibWithAppContext:_appContext];
		vc.diversionPath = _diversionPath;
		[self.navigationController pushViewController:vc animated:TRUE];		
	}
}

- (void) didSelectMarkAsReadRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {

	OBAModelDAO * modelDao = _appContext.modelDao;
	BOOL isRead = ! [modelDao isVisitedSituationWithId:_situation.situationId];
	[modelDao setVisited:isRead forSituationWithId:_situation.situationId];
	
	UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
	cell.textLabel.text = isRead ? @"Mark as Unread" : @"Mark as Read";
	[tableView deselectRowAtIndexPath:indexPath animated:TRUE];
}

- (NSString*) getDetails {
	
	NSMutableString * buffer = [NSMutableString stringWithCapacity:0];
	
	if( _situation.description )
		[buffer appendString:_situation.description];
	
	if( [buffer length] > 0 ) 
		[buffer appendString:@"\n\n"];
	
	if( _situation.advice )
		[buffer appendString:_situation.advice];
	
	return buffer;
}

@end



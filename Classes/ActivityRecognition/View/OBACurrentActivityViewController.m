//
//  OBACurrentActivityViewController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 10/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OBACurrentActivityViewController.h"
#import "OBAUITableViewCell.h"
#import "OBATripStatus.h"


@implementation OBACurrentActivityViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
	if( self = [super initWithStyle:UITableViewStyleGrouped] ) {
		_appContext = [appContext retain];
		_nearbyTrips = [[NSArray alloc] init];
	}
	return self;
}


- (void)dealloc {
	[_nearbyTrips release];
	[_appContext release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	OBAActivityListeners * listeners = _appContext.activityListeners;
	[listeners addListener:self];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	OBAActivityListeners * listeners = _appContext.activityListeners;
	[listeners removeListener:self];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_nearbyTrips count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    OBATripStatus * status = [_nearbyTrips objectAtIndex:indexPath.row];
	OBARoute * route = status.route;
	OBATrip * trip = status.trip;
	
	NSString * routeShortName = [OBACommon getBestNameFirst:trip.routeShortName second:route.shortName third:route.longName];
	NSString * destination = trip.tripHeadsign;
	
	double distance = -1;
	OBALocationManager * manager = _appContext.locationManager;
	CLLocation * currentLocation = manager.currentLocation;
	if( currentLocation )
		distance = [currentLocation distanceFromLocation:status.position];
	
	int scheduleDeviation = status.scheduleDeviation;
	NSString * predicted = status.predicted ? @"true" : @"false";
	
	NSString * label = [NSString stringWithFormat:@"%@ - %@",routeShortName,destination];
	NSString * detailLabel = [NSString stringWithFormat:@"dist=%0.0fm delta=%ds pred=%@",distance, scheduleDeviation,predicted];
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
	cell.textLabel.text = label;
	cell.detailTextLabel.text = detailLabel;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}

#pragma mark OBAActivityListener

NSComparisonResult tripStatusSortByDistance(id o1, id o2, void * context) {
	OBATripStatus * ts1 = o1;
	OBATripStatus * ts2 = o2;
	OBAApplicationContext * appContext = (OBAApplicationContext*) context;
	
	OBALocationManager * manager = appContext.locationManager;
	CLLocation * currentLocation = manager.currentLocation;
	if( ! currentLocation )
		return NSOrderedSame;
	
	double d1 = [currentLocation distanceFromLocation:ts1.position];
	double d2 = [currentLocation distanceFromLocation:ts2.position];

	return d1 == d2 ? NSOrderedSame : (d1 < d2  ? NSOrderedAscending : NSOrderedDescending);
}


- (void) nearbyTrips:(NSArray*)nearbyTrips {
	
	NSMutableArray * elements = [NSMutableArray array];
	[elements addObjectsFromArray:nearbyTrips];
	[elements sortUsingFunction:tripStatusSortByDistance context:_appContext];
	
	[_nearbyTrips release];
	_nearbyTrips = [elements retain];
	[self.tableView reloadData];
}

@end


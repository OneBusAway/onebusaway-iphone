#import "OBATripScheduleListViewController.h"
#import "OBATripStopTimeV2.h"
#import "OBAUITableViewCell.h"


typedef enum {
	OBASectionTypeNone,
	OBASectionTypeSchedule,
	OBASectionTypePreviousStops,
	OBASectionTypeConnections
} OBASectionType;


@interface OBATripScheduleListViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (BOOL) hasTripConnections;
- (NSUInteger) computeNumberOfScheduleRows;

- (UITableViewCell*) tableView:(UITableView*)tableView scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView previousStopsCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView connectionsCellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@implementation OBATripScheduleListViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)context tripDetails:(OBATripDetailsV2*)tripDetails {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		_appContext = [context retain];
		_tripDetails = [tripDetails retain];
		_currentStopIndex = -1;
		_showPreviousStops = FALSE;
		
		self.navigationItem.title = @"Trip Schedule";						
    }
    return self;
}

- (void)dealloc {
	[_appContext release];
	[_tripDetails release];	 
    [super dealloc];
}

- (void) setCurrentStopId:(NSString*)stopId {
	OBATripScheduleV2 * sched = _tripDetails.schedule;
	NSInteger index = 0;
	for( OBATripStopTimeV2 * stopTime in sched.stopTimes ) {
		if( [stopTime.stopId isEqual:stopId] ) {
			_currentStopIndex = index;
			return;
		}
		index++;	
	}
	_currentStopIndex = -1;
}

#pragma mark -
#pragma mark View lifecycle

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSInteger sections = 1;
	if( _currentStopIndex > 0 )
		sections++;
	if([self hasTripConnections] )
		sections++;
	return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeConnections:
			return @"Connections:";
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeSchedule:
			return [self computeNumberOfScheduleRows];
			break;
		case OBASectionTypePreviousStops:
			return 1;
		case OBASectionTypeConnections: {
			NSInteger count = 0;
			if( _tripDetails.schedule.previousTripId )
				count++;
			if( _tripDetails.schedule.nextTripId )
				count++;
			return count;
		}			
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
    
	switch(sectionType) {
		case OBASectionTypeSchedule:
			return [self tableView:tableView scheduleCellForRowAtIndexPath:indexPath];
		case OBASectionTypePreviousStops:
			return [self tableView:tableView previousStopsCellForRowAtIndexPath:indexPath];
		case OBASectionTypeConnections:
			return [self tableView:tableView connectionsCellForRowAtIndexPath:indexPath];
		default:
			return [UITableViewCell getOrCreateCellForTableView:tableView];
	}
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


@end


@implementation OBATripScheduleListViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	
	NSInteger offset = 1;
	
	if( section == 0 )
		return OBASectionTypeSchedule;
	
	if( _currentStopIndex > 0 ) {
		if( section == offset )
			return OBASectionTypePreviousStops;	
		offset++;
	}
	
	if( [self hasTripConnections] ) {
		if( section == offset )
			return OBASectionTypeConnections;
		offset++;
	}

	return OBASectionTypeNone;
}

- (BOOL) hasTripConnections {
	OBATripScheduleV2 * sched = _tripDetails.schedule;
	return sched.previousTripId != nil || sched.nextTripId != nil;
}

- (NSUInteger) computeNumberOfScheduleRows {
	OBATripScheduleV2 * sched = _tripDetails.schedule;
	NSArray * stopTimes = sched.stopTimes;
	NSUInteger count = [stopTimes count];
	if( ! _showPreviousStops && _currentStopIndex > 0 )
		count = 1 + MAX(0,count-_currentStopIndex);
	return count;
}

- (UITableViewCell*) tableView:(UITableView*)tableView scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath {

	if (! _showPreviousStops && _currentStopIndex > 0 && indexPath.row == 0 ) {
		
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.text = [NSString stringWithFormat:@"Hiding %d previous stops",_currentStopIndex];
		cell.textLabel.textColor = [UIColor grayColor];
		return cell;
	}

	NSArray * stopTimes = _tripDetails.schedule.stopTimes;
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;		
	
	NSUInteger index = indexPath.row-1;
	if( ! _showPreviousStops && _currentStopIndex > 0 )
		index += _currentStopIndex;
	OBATripStopTimeV2 * stopTime = [stopTimes objectAtIndex:index];
	OBAStopV2 * stop = stopTime.stop;
	cell.textLabel.text = stop.name;
	cell.textLabel.textColor = [UIColor blackColor];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"time=%d",stopTime.arrivalTime];
	return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView previousStopsCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.text = _showPreviousStops ? @"Hide previous stops" : @"Show previous stops";
	return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView connectionsCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	OBATripScheduleV2 * sched = _tripDetails.schedule;
	
	NSInteger offset = 0;
	if( sched.previousTripId != nil ) {
		if( indexPath.row == offset ) {
			OBATripV2 * trip = [sched previousTrip];
			cell.textLabel.text = [NSString stringWithFormat:@"Inbound from: %@",trip.asLabel];
		}
		offset++;
	}
	
	if( sched.nextTripId != nil ) {
		if( indexPath.row == offset ) {
			OBATripV2 * trip = [sched nextTrip];
			cell.textLabel.text = [NSString stringWithFormat:@"Continues as: %@",trip.asLabel];
		}
		offset++;
	}

	return cell;	
}

@end



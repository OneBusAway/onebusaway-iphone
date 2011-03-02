#import "OBATripScheduleListViewController.h"
#import "OBATripStopTimeV2.h"
#import "OBAUITableViewCell.h"
#import "OBATripDetailsViewController.h"
#import "OBATripScheduleMapViewController.h"
#import "OBAUIKit.h"
#import "OBAStopViewController.h"


typedef enum {
	OBASectionTypeNone,
	OBASectionTypeLoading,
	OBASectionTypeSchedule,
	OBASectionTypePreviousStops,
	OBASectionTypeConnections
} OBASectionType;


@interface OBATripScheduleListViewController (Private)

- (void) handleTripDetails;

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (BOOL) hasTripConnections;
- (NSUInteger) computeNumberOfScheduleRows;
- (NSDate*) getStopTimeAsDate:(NSInteger)stopTime;

- (UITableViewCell*) tableView:(UITableView*)tableView loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView previousStopsCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView connectionsCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView didSelectScheduleRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectPreviousStopsRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectConnectionsRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@implementation OBATripScheduleListViewController

@synthesize tripDetails = _tripDetails;
@synthesize currentStopId;

- (id) initWithApplicationContext:(OBAApplicationContext*)context tripInstance:(OBATripInstanceRef*)tripInstance {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		_appContext = [context retain];
		_tripInstance = [tripInstance retain];
		_currentStopIndex = -1;
		_showPreviousStops = FALSE;
		
		_timeFormatter = [[NSDateFormatter alloc] init];
		[_timeFormatter setDateStyle:NSDateFormatterNoStyle];
		[_timeFormatter setTimeStyle:NSDateFormatterShortStyle];		
		
		CGRect r = CGRectMake(0, 0, 160, 33);
		_progressView = [[OBAProgressIndicatorView alloc] initWithFrame:r];
		[self.navigationItem setTitleView:_progressView];
		
		UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStyleBordered target:self action:@selector(showMap:)];
		self.navigationItem.rightBarButtonItem = item;
		[item release];
		
		UIBarButtonItem * backItem = [[UIBarButtonItem alloc] initWithTitle:@"Schedule" style:UIBarButtonItemStyleBordered target:nil action:nil];
		self.navigationItem.backBarButtonItem = backItem;
		[backItem release];		
    }
    return self;
}

- (void)dealloc {
	[_request cancel];
	
	[_appContext release];
	[_tripInstance release];
	[_tripDetails release];	 
	[_request release];
	[_timeFormatter release];
	[_progressView release];
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated {

	if( _tripDetails == nil && _tripInstance != nil ) {
		[self.tableView reloadData];
		_request = [[_appContext.modelService requestTripDetailsForTripInstance:_tripInstance withDelegate:self withContext:nil] retain];
	}
	else {
		[self handleTripDetails];
	}
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	OBAEntryWithReferencesV2 * entry = obj;
	_tripDetails = [entry.entry retain];
	[self handleTripDetails];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
	if( code == 404 )
		[_progressView setMessage:@"Trip not found" inProgress:FALSE progress:0];
	else
		[_progressView setMessage:@"Unknown error" inProgress:FALSE progress:0];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
	OBALogWarningWithError(error, @"Error");
	[_progressView setMessage:@"Error connecting" inProgress:FALSE progress:0];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
	[_progressView setInProgress:TRUE progress:progress];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	if( _tripDetails == nil )
		return 1;
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
		case OBASectionTypeLoading:
			return 1;			
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
		case OBASectionTypeLoading:
			return [self tableView:tableView loadingCellForRowAtIndexPath:indexPath];
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

	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeSchedule:
			[self tableView:tableView didSelectScheduleRowAtIndexPath:indexPath];
			break;
		case OBASectionTypePreviousStops:
			[self tableView:tableView didSelectPreviousStopsRowAtIndexPath:indexPath];
			break;			
		case OBASectionTypeConnections:
			[self tableView:tableView didSelectConnectionsRowAtIndexPath:indexPath];
			break;
		default:
			break;
	}
}


- (void) showMap:(id)sender {
	OBATripScheduleMapViewController * vc = [OBATripScheduleMapViewController loadFromNibWithAppContext:_appContext];
	vc.tripDetails = _tripDetails;
	vc.currentStopId = self.currentStopId;
	[self.navigationController replaceViewController:vc animated:TRUE];
}

@end


@implementation OBATripScheduleListViewController (Private)

- (void) handleTripDetails {

	[_progressView setMessage:@"Trip Schedule" inProgress:FALSE progress:0];

	NSString * stopId = self.currentStopId;
	OBATripScheduleV2 * sched = _tripDetails.schedule;
	NSInteger index = 0;
	for( OBATripStopTimeV2 * stopTime in sched.stopTimes ) {
		if( [stopTime.stopId isEqual:stopId] ) {
			_currentStopIndex = index;
			[self.tableView reloadData];
			return;
		}
		index++;	
	}
	_currentStopIndex = -1;
	[self.tableView reloadData];
}

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	
	if( _tripDetails == nil )
		return OBASectionTypeLoading;
	
	NSInteger offset = 0;

	if( _currentStopIndex > 0 ) {
		if( section == offset )
			return OBASectionTypePreviousStops;	
		offset++;
	}
	
	if( section == offset )
		return OBASectionTypeSchedule;
	offset++;
	
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

- (NSDate*) getStopTimeAsDate:(NSInteger)stopTime {
	
	long long serviceDate = 0;
	NSInteger scheduleDeviation = 0;
	
	OBATripStatusV2 * status = _tripDetails.status;
	if( status ) {
		serviceDate = status.serviceDate;
		scheduleDeviation = status.scheduleDeviation;
	}
	
	return [NSDate dateWithTimeIntervalSince1970:(serviceDate/1000 + stopTime + scheduleDeviation)];
}

- (UITableViewCell*) tableView:(UITableView*)tableView loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleDefault];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.text = @"Loading...";
	return cell;	
}

- (UITableViewCell*) tableView:(UITableView*)tableView scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath {

	BOOL hidingPreviousStops = ! _showPreviousStops && _currentStopIndex > 0;
	
	if ( hidingPreviousStops && indexPath.row == 0 ) {
		
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleDefault];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.text = [NSString stringWithFormat:@"Hiding %d previous stops",_currentStopIndex];
		cell.textLabel.textColor = [UIColor grayColor];
		return cell;
	}

	OBATripScheduleV2 * schedule = _tripDetails.schedule;
	NSArray * stopTimes = schedule.stopTimes;
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	NSUInteger index = indexPath.row;
	
	if( hidingPreviousStops )
		index += _currentStopIndex - 1;
	OBATripStopTimeV2 * stopTime = [stopTimes objectAtIndex:index];
	OBAStopV2 * stop = stopTime.stop;
	cell.textLabel.text = stop.name;
	cell.textLabel.textColor = [UIColor blackColor];
	
	if( schedule.frequency ) {
		OBATripStopTimeV2 * firstStopTime = [stopTimes objectAtIndex:0];
		int minutes = (stopTime.arrivalTime - firstStopTime.departureTime) / 60;
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%d mins",minutes];									  
	}
	else {
		NSDate * time = [self getStopTimeAsDate:stopTime.arrivalTime];
		cell.detailTextLabel.text = [_timeFormatter stringFromDate:time];
	}
	
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
			cell.textLabel.text = [NSString stringWithFormat:@"Starts as %@",trip.asLabel];
		}
		offset++;
	}
	
	if( sched.nextTripId != nil ) {
		if( indexPath.row == offset ) {
			OBATripV2 * trip = [sched nextTrip];
			cell.textLabel.text = [NSString stringWithFormat:@"Continues as %@",trip.asLabel];
		}
		offset++;
	}

	return cell;	
}

- (void)tableView:(UITableView *)tableView didSelectScheduleRowAtIndexPath:(NSIndexPath *)indexPath {
	
	BOOL hidingPreviousStops = ! _showPreviousStops && _currentStopIndex > 0;
	
	if ( hidingPreviousStops && indexPath.row == 0 )
		return;
	
	NSArray * stopTimes = _tripDetails.schedule.stopTimes;
	
	NSUInteger index = indexPath.row;
	
	if( hidingPreviousStops )
		index += _currentStopIndex - 1;
	OBATripStopTimeV2 * stopTime = [stopTimes objectAtIndex:index];
	
	OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationContext:_appContext stopId:stopTime.stopId];
	[self.navigationController pushViewController:vc animated:TRUE];
	[vc release];
}

- (void)tableView:(UITableView *)tableView didSelectPreviousStopsRowAtIndexPath:(NSIndexPath *)indexPath {
	_showPreviousStops = ! _showPreviousStops;
	[self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectConnectionsRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBATripScheduleV2 * sched = _tripDetails.schedule;
	OBATripInstanceRef * tripInstance = _tripDetails.tripInstance;
	
	NSInteger offset = 0;
	if( sched.previousTripId != nil ) {
		if( indexPath.row == offset ) {
			OBATripInstanceRef * prevTripInstance = [tripInstance copyWithNewTripId:sched.previousTripId];
			OBATripDetailsViewController * vc = [[OBATripDetailsViewController alloc] initWithApplicationContext:_appContext tripInstance:prevTripInstance];
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			return;
		}
		offset++;
	}
	
	if( sched.nextTripId != nil ) {
		if( indexPath.row == offset ) {
			OBATripInstanceRef * nextTripInstance = [tripInstance copyWithNewTripId:sched.nextTripId];
			OBATripDetailsViewController * vc = [[OBATripDetailsViewController alloc] initWithApplicationContext:_appContext tripInstance:nextTripInstance];
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			return;
		}
		offset++;
	}
}

@end



#import "OBAArrivalAndDepartureViewController.h"
#import "OBAUITableViewCell.h"
#import "OBATripScheduleMapViewController.h"
#import "OBATripScheduleListViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBASituationsViewController.h"
#import "OBALogger.h"
#import "OBAPresentation.h"


typedef enum {
	OBASectionTypeNone,
	OBASectionTypeTitle,
	OBASectionTypeServiceAlerts,
	OBASectionTypeSchedule,
	OBASectionTypeActions
} OBASectionType;


@interface OBAArrivalAndDepartureViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell*) titleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) serviceAlertsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) actionCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;

- (void) didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void) didSelectScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void) didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end


@implementation OBAArrivalAndDepartureViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext arrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [appContext retain];
		_arrivalAndDeparture = [arrivalAndDeparture retain];

	}
	return self;
}

- (void)dealloc {
	[_appContext release];
	[_arrivalAndDeparture release];
    [super dealloc];
}

#pragma mark UIViewController methods

- (void)viewWillAppear:(BOOL)animated {
	
	// Refresh the unread service alert count
	OBAModelDAO * modelDao = _appContext.modelDao;
	_unreadServiceAlertCount = [modelDao getUnreadServiceAlertCount:_arrivalAndDeparture.situationIds];
	_serviceAlertCount = [_arrivalAndDeparture.situationIds count];
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	int count = 3;
	if( _unreadServiceAlertCount > 0 )
		count++;
	return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionTypeTitle:
			return 1;
		case OBASectionTypeServiceAlerts:
			return 1;
		case OBASectionTypeSchedule:
			return 2;
		case OBASectionTypeActions:
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
			return [self titleCellForRowAtIndexPath:indexPath tableView:tableView];
		case OBASectionTypeServiceAlerts:
			return [self serviceAlertsCellForRowAtIndexPath:indexPath tableView:tableView];
		case OBASectionTypeSchedule:
			return [self scheduleCellForRowAtIndexPath:indexPath tableView:tableView];
		case OBASectionTypeActions:
			return [self actionCellForRowAtIndexPath:indexPath tableView:tableView];
		default:
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		
		case OBASectionTypeServiceAlerts:
			[self didSelectServiceAlertRowAtIndexPath:indexPath tableView:tableView];
			break;
			
		case OBASectionTypeSchedule:
			[self didSelectScheduleRowAtIndexPath:indexPath tableView:tableView];
			break;			
			
		case OBASectionTypeActions:
			[self didSelectActionRowAtIndexPath:indexPath tableView:tableView];
			break;

		default:
			break;
	}
	
}

@end


@implementation OBAArrivalAndDepartureViewController (Private)


- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	
	NSUInteger offset = 0;
	
	if( offset == section )
		return OBASectionTypeTitle;
	offset++;
	
	if( _unreadServiceAlertCount > 0 ) {
		if( offset == section )
			return OBASectionTypeServiceAlerts;
		offset++;
	}
	
	if( offset == section )
		return OBASectionTypeSchedule;
	offset++;
	
	if( offset == section )
		return OBASectionTypeActions;
	
	return OBASectionTypeNone;
}

- (UITableViewCell*) titleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	NSString * routeShortName = [OBAPresentation getRouteShortNameForArrivalAndDeparture:_arrivalAndDeparture];
	NSString * tripHeadsign = [OBAPresentation getTripHeadsignForArrivalAndDeparture:_arrivalAndDeparture];
	cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", routeShortName, tripHeadsign];
	cell.textLabel.textColor = [UIColor blackColor];
	cell.textLabel.textAlignment = UITextAlignmentLeft;	
	
	cell.detailTextLabel.text = @"Schedule data only";
	cell.detailTextLabel.textColor = [UIColor blackColor];
	cell.detailTextLabel.textAlignment = UITextAlignmentLeft;	
	
	OBATripStatusV2 * status = _arrivalAndDeparture.tripStatus;
	if( status && status.predicted ) {
		NSInteger scheduleDeviation = status.scheduleDeviation/60;
		NSString * label = @"";
		if( scheduleDeviation <= -2 )
			label = [NSString stringWithFormat:@"%d minutes early",(-scheduleDeviation)];
		else if (scheduleDeviation < 2 )
			label = @"on time";
		else
			label = [NSString stringWithFormat:@"%d minutes late",scheduleDeviation];
		
		cell.detailTextLabel.text = [NSString stringWithFormat:@"Vehicle # %@ - %@",status.vehicleId,label];
	}
	
	return cell;
}

- (UITableViewCell*) serviceAlertsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
	return [OBAPresentation tableViewCellForUnreadServiceAlerts:_unreadServiceAlertCount tableView:tableView];
}

- (UITableViewCell*) scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.textLabel.textColor = [UIColor blackColor];
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	
	switch (indexPath.row) {
		case 0:
			cell.textLabel.text = @"Show as map";
			break;
		case 1:
			cell.textLabel.text = @"Show as list";
			break;
	}
	
	return cell;
}


- (UITableViewCell*) actionCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
	
	if( indexPath.row == 0 ) {
		return [OBAPresentation tableViewCellForServiceAlerts:_unreadServiceAlertCount totalCount:_serviceAlertCount tableView:tableView];
	}
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.textLabel.textColor = [UIColor blackColor];
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	
	
	switch (indexPath.row) {
		case 0: {
			cell.textLabel.text = @"Service Alerts";
			break;
		}
		case 1: {
			cell.textLabel.text = @"Report a problem for this trip";
			break;
		}
	}
	
	return cell;
}
	
- (void) didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	[OBAPresentation showSituations:_arrivalAndDeparture.situations withAppContext:_appContext navigationController:self.navigationController];
}

- (void) didSelectScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	if( indexPath.row == 0 ) {
		OBATripScheduleMapViewController * vc = [OBATripScheduleMapViewController loadFromNibWithAppContext:_appContext];
		// vc.tripDetails = _tripDetails;
		vc.currentStopId = _arrivalAndDeparture.stopId;
		[self.navigationController pushViewController:vc animated:TRUE];
	}			
	else if( indexPath.row == 1 ) {
		/*
		OBATripScheduleListViewController * vc = [[OBATripScheduleListViewController alloc] initWithApplicationContext:_appContext tripDetails:_tripDetails];
		[vc setCurrentStopId:self.currentStopId];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
		 */
	}
}

- (void) didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	if( indexPath.row == 0 ) {
		[OBAPresentation showSituations:_arrivalAndDeparture.situations withAppContext:_appContext navigationController:self.navigationController];
	}
	else if( indexPath.row == 1 ) {
		/*
		OBAReportProblemWithTripViewController * vc = [[OBAReportProblemWithTripViewController alloc] initWithApplicationContext:_appContext tripDetails:_tripDetails];
		vc.currentStopId = self.currentStopId;
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
		*/
	}
}

@end


#import "OBAArrivalAndDepartureViewController.h"
#import "OBAUITableViewCell.h"
#import "OBATripScheduleMapViewController.h"
#import "OBATripScheduleListViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBASituationsViewController.h"
#import "OBAVehicleDetailsController.h"
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

- (void) showSituations;

@end


@implementation OBAArrivalAndDepartureViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext arrivalAndDepartureInstance:(OBAArrivalAndDepartureInstanceRef*)instance {
	if( self = [super initWithApplicationContext:appContext] ) {
		_instance = [instance retain];
		_arrivalAndDeparture = nil;
		_arrivalCellFactory = [[OBAArrivalEntryTableViewCellFactory alloc] initWithAppContext:_appContext tableView:self.tableView];
		_arrivalCellFactory.showServiceAlerts = FALSE;
		self.refreshable = TRUE;
		self.refreshInterval = 30;
		self.showUpdateTime = TRUE;
	}
	return self;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext arrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
	self = [self initWithApplicationContext:appContext arrivalAndDepartureInstance:arrivalAndDeparture.instance];
	_arrivalAndDeparture = [arrivalAndDeparture retain];
	return self;	
}

- (void)dealloc {
	[_instance release];
	[_arrivalAndDeparture release];
	[_arrivalCellFactory release];
	[_serviceAlerts release];
    [super dealloc];
}

- (BOOL) isLoading {
	return _arrivalAndDeparture == nil;
}

- (id<OBAModelServiceRequest>) handleRefresh {
	return [_appContext.modelService requestArrivalAndDepartureForStop:_instance withDelegate:self withContext:nil];
}

-(void) handleData:(id)obj context:(id)context {
	OBAEntryWithReferencesV2 * entry = obj;
	_arrivalAndDeparture = [entry.entry retain];
}

- (void) handleDataChanged {
	// Refresh the unread service alert count
	OBAModelDAO * modelDao = _appContext.modelDao;
	_serviceAlerts = [[modelDao getServiceAlertsModelForSituations:_arrivalAndDeparture.situations] retain];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	if( [self isLoading] )
		return [super numberOfSectionsInTableView:tableView];
	
	int count = 3;
	if( _serviceAlerts.unreadCount > 0 )
		count++;
	return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if( [self isLoading] )
		return [super tableView:tableView numberOfRowsInSection:section];
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionTypeTitle:
			return 1;
		case OBASectionTypeServiceAlerts:
			return 1;
		case OBASectionTypeSchedule:
			return 2;
		case OBASectionTypeActions: {
			int count = 2;
			if( _arrivalAndDeparture.tripStatus.vehicleId )
				count++;
			return count;
		}
		default:
			return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	if( [self isLoading] )
		return nil;
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeSchedule:
			return @"Trip Details:";
		case OBASectionTypeActions:
			return @"Actions:";
		default:
			return nil;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if( [self isLoading] )
		return [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
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
	
	if( [self isLoading] ) {
		[self tableView:tableView didSelectRowAtIndexPath:indexPath];
		return;
	}
	
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
	
	if( _serviceAlerts.unreadCount > 0 ) {
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
	
	OBAArrivalEntryTableViewCell * cell = [_arrivalCellFactory createCellForArrivalAndDeparture:_arrivalAndDeparture];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;	
	return cell;
}

- (UITableViewCell*) serviceAlertsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
	return [OBAPresentation tableViewCellForUnreadServiceAlerts:_serviceAlerts tableView:tableView];
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
	
	switch (indexPath.row) {
		case 0:{
			return [OBAPresentation tableViewCellForServiceAlerts:_serviceAlerts tableView:tableView];
		}
		case 1: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.textColor = [UIColor blackColor];
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.textLabel.text = @"Report a problem for this trip";
			return cell;			
		}
		case 2: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.textColor = [UIColor blackColor];
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.textLabel.text = @"Vehicle Info";
			return cell;			
		}
		default:
			break;
	}
	
	return nil;
}
	
- (void) didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	[self showSituations];
}

- (void) didSelectScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	OBATripInstanceRef * tripInstance = _arrivalAndDeparture.tripInstance;
	if( indexPath.row == 0 ) {
		OBATripScheduleMapViewController * vc = [OBATripScheduleMapViewController loadFromNibWithAppContext:_appContext];
		vc.tripInstance = tripInstance;
		vc.currentStopId = _arrivalAndDeparture.stopId;
		[self.navigationController pushViewController:vc animated:TRUE];
	}			
	else if( indexPath.row == 1 ) {
		OBATripScheduleListViewController * vc = [[OBATripScheduleListViewController alloc] initWithApplicationContext:_appContext tripInstance:tripInstance];
		vc.currentStopId = _arrivalAndDeparture.stopId;
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
}

- (void) didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	
	switch (indexPath.row) {
		case 0: {
			[self showSituations];
			break;
		}
		case 1: {
			OBATripInstanceRef * tripInstance = _arrivalAndDeparture.tripInstance;
			OBAReportProblemWithTripViewController * vc = [[OBAReportProblemWithTripViewController alloc] initWithApplicationContext:_appContext tripInstance:tripInstance trip:_arrivalAndDeparture.trip];
			vc.currentStopId = _arrivalAndDeparture.stopId;
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
		case 2: {
			OBAVehicleDetailsController * vc = [[OBAVehicleDetailsController alloc] initWithApplicationContext:_appContext vehicleId:_arrivalAndDeparture.tripStatus.vehicleId];
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
	}
}

- (void) showSituations {
	NSDictionary * args = [NSDictionary dictionaryWithObject:_arrivalAndDeparture forKey:@"arrivalAndDeparture"];
	[OBAPresentation showSituations:_arrivalAndDeparture.situations withAppContext:_appContext navigationController:self.navigationController args:args];
}

@end


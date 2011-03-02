#import "OBAVehicleDetailsController.h"
#import "OBAUITableViewCell.h"
#import "OBATripScheduleMapViewController.h"
#import "OBATripScheduleListViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBASituationsViewController.h"
#import "OBALogger.h"
#import "OBAPresentation.h"


typedef enum {
	OBASectionTypeNone,
	OBASectionTypeVehicleDetails,
	OBASectionTypeTripDetails,
	OBASectionTypeTripSchedule
} OBASectionType;


@interface OBAVehicleDetailsController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell*) vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) tripDetailsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) tripScheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;

- (void) didSelectTripScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end


@implementation OBAVehicleDetailsController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext vehicleId:(NSString*)vehicleId {
	if( self = [super initWithApplicationContext:appContext] ) {
		_vehicleId = [vehicleId retain];
		self.refreshable = TRUE;
		self.refreshInterval = 30;
		self.showUpdateTime = TRUE;
	}
	return self;
}

- (void)dealloc {
	[_vehicleId release];
	[_vehicleStatus release];
    [super dealloc];
}

- (BOOL) isLoading {
	return _vehicleStatus == nil;
}

- (id<OBAModelServiceRequest>) handleRefresh {
	return [_appContext.modelService requestVehicleForId:_vehicleId withDelegate:self withContext:nil];
}

-(void) handleData:(id)obj context:(id)context {
	OBAEntryWithReferencesV2 * entry = obj;
	_vehicleStatus = [entry.entry retain];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	if( [self isLoading] )
		return [super numberOfSectionsInTableView:tableView];
	
	int count = 1;
	if( _vehicleStatus.tripStatus )
		count += 2;
	return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if( [self isLoading] )
		return [super tableView:tableView numberOfRowsInSection:section];
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionTypeVehicleDetails:
			return 1;
		case OBASectionTypeTripDetails:
			return 2;
		case OBASectionTypeTripSchedule:
			return 2;
		default:
			return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	if( [self isLoading] )
		return nil;
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeVehicleDetails:
			return @"Vehicle Details:";
		case OBASectionTypeTripDetails:
			return @"Active Trip Details:";
		case OBASectionTypeTripSchedule:
			return @"Active Trip Schedule:";
		default:
			return nil;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if( [self isLoading] )
		return [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeVehicleDetails:
			return [self vehicleCellForRowAtIndexPath:indexPath tableView:tableView];
		case OBASectionTypeTripDetails:
			return [self tripDetailsCellForRowAtIndexPath:indexPath tableView:tableView];
		case OBASectionTypeTripSchedule:
			return [self tripScheduleCellForRowAtIndexPath:indexPath tableView:tableView];
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
		
		case OBASectionTypeTripSchedule:
			[self didSelectTripScheduleRowAtIndexPath:indexPath tableView:tableView];
			break;			

		default:
			break;
	}
	
}

@end


@implementation OBAVehicleDetailsController (Private)


- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	
	NSUInteger offset = 0;
	
	if( offset == section )
		return OBASectionTypeVehicleDetails;
	offset++;
	
	if( _vehicleStatus.tripStatus ) {
		if( offset == section )
			return OBASectionTypeTripDetails;
		offset++;
		
		if( offset == section )
			return OBASectionTypeTripSchedule;
		offset++;
	}
	
	return OBASectionTypeNone;
}

- (UITableViewCell*) vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;

	cell.textLabel.textColor = [UIColor blackColor];
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	cell.textLabel.text = [NSString stringWithFormat:@"Vehicle: %@", _vehicleStatus.vehicleId];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];	
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:kCFDateFormatterNoStyle];	
	NSString * result = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_vehicleStatus.lastUpdateTime/1000.0]];
	[dateFormatter release];

	cell.detailTextLabel.textColor = [UIColor blackColor];
	cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"Last update: %@", result];

	return cell;
}

- (UITableViewCell*) tripDetailsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
	
	OBATripStatusV2 * tripStatus = _vehicleStatus.tripStatus;
	OBATripV2 * trip = tripStatus.activeTrip;
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.textLabel.textColor = [UIColor blackColor];
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	
	switch (indexPath.row) {
		case 0: {
			NSString * routeShortName = [OBAPresentation getRouteShortNameForRoute:trip.route];
			NSString * tripHeadsign = [OBAPresentation getTripHeadsignForTrip:trip];
			cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", routeShortName, tripHeadsign];
			break;
		}
		case 1: {
			
			if( tripStatus.frequency ) { 
				cell.textLabel.text = [NSString stringWithFormat:@"Schedule deviation: N/A"];
			}
			else {
				NSInteger sd = tripStatus.scheduleDeviation;
				NSString * label = @" ";
				if( sd > 0 ) {
					label = @" late";
				}
				else if( sd < 0 ) {
					label = @" early";
					sd = -sd;
				}
				
				NSInteger mins = sd / 60;
				NSInteger secs = sd % 60;
				
				cell.textLabel.text = [NSString stringWithFormat:@"Schedule deviation: %dm %ds%@",mins, secs, label];
			}
			break;
		}
	}
	
	return cell;
}

- (UITableViewCell*) tripScheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
	
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
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
	}
	
	return cell;
}

- (void) didSelectTripScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	
	OBATripStatusV2 * tripStatus = _vehicleStatus.tripStatus;
	OBATripInstanceRef * tripInstance = tripStatus.tripInstance;
	
	switch (indexPath.row) {
		case 0: {
			OBATripScheduleMapViewController * vc = [OBATripScheduleMapViewController loadFromNibWithAppContext:_appContext];
			vc.tripInstance = tripInstance;
			[self.navigationController pushViewController:vc animated:TRUE];			
			break;
		}
		case 1: {
			OBATripScheduleListViewController * vc = [[OBATripScheduleListViewController alloc] initWithApplicationContext:_appContext tripInstance:tripInstance];
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
	}
}

@end


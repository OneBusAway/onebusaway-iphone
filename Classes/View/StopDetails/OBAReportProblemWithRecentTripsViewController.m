#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBAReportProblemWithTripViewController.h"

@interface OBATripDetailsHandler : NSObject <OBAModelServiceDelegate>

@end


@implementation OBAReportProblemWithRecentTripsViewController 

- (void) customSetup {
	_showTitle = FALSE;
	_showActions = FALSE;
	_arrivalCellFactory.showServiceAlerts = FALSE;
	_showServiceAlerts = FALSE;
	_minutesBefore = 20;
	
	_tripDetailsHandler = [[OBATripDetailsHandler alloc] init];
}

- (void) dealloc {
	[_tripDetailsHandler release];
	[super dealloc];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {	
	OBAStopSectionType sectionType = [self sectionTypeForSection:section];
	if (sectionType == OBAStopSectionTypeArrivals)
		return @"Select the trip with a problem:";
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectTripRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray * arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;
	OBAArrivalAndDepartureV2 * arrivalAndDeparture = [arrivals objectAtIndex:indexPath.row];
	if( arrivalAndDeparture ) {
		OBATripInstanceRef * tripInstance = arrivalAndDeparture.tripInstance;
		[_appContext.modelService requestTripDetailsForTripInstance:tripInstance withDelegate:_tripDetailsHandler withContext:self];
	}
}

@end


@implementation OBATripDetailsHandler

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	OBAReportProblemWithRecentTripsViewController * parent = context;
	OBAEntryWithReferencesV2 * entry = obj;
	OBATripDetailsV2 * tripDetails = entry.entry;
	if( tripDetails ) {
		OBATripInstanceRef * tripInstance = tripDetails.tripInstance;
		OBAReportProblemWithTripViewController * vc = [[OBAReportProblemWithTripViewController alloc] initWithApplicationContext:parent.appContext tripInstance:tripInstance trip:tripDetails.trip];
		vc.currentStopId = parent.stopId;
		[parent.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
}

@end




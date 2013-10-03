#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBAReportProblemWithTripViewController.h"

@interface OBATripDetailsHandler : NSObject <OBAModelServiceDelegate>

@end

@interface OBAReportProblemWithRecentTripsViewController ()
@property(strong) id tripDetailsHandler;
@end


@implementation OBAReportProblemWithRecentTripsViewController 

- (void) customSetup {
    self.showTitle = NO;
    self.showActions = NO;
    self.arrivalCellFactory.showServiceAlerts = NO;
    self.showServiceAlerts = NO;
    self.minutesBefore = 30;
    
    self.tripDetailsHandler = [[OBATripDetailsHandler alloc] init];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {    
    OBAStopSectionType sectionType = [self sectionTypeForSection:section];
    if (sectionType == OBAStopSectionTypeArrivals) {
        return NSLocalizedString(@"Select the trip with a problem:",@"sectionType == OBAStopSectionTypeArrivals");
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectTripRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *arrivals = self.showFilteredArrivals ? self.filteredArrivals : self.allArrivals;
    if ((arrivals.count == 0 && indexPath.row == 1) || (arrivals.count == indexPath.row && arrivals.count > 0)) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        self.minutesAfter += 30;
        [self refresh];
    } else if (arrivals.count > 0) {
        OBAArrivalAndDepartureV2 * arrivalAndDeparture = arrivals[indexPath.row];
        
        if (arrivalAndDeparture) {
            OBATripInstanceRef * tripInstance = arrivalAndDeparture.tripInstance;
            [self.appDelegate.modelService requestTripDetailsForTripInstance:tripInstance withDelegate:self.tripDetailsHandler withContext:self];
        }
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
        OBAReportProblemWithTripViewController * vc = [[OBAReportProblemWithTripViewController alloc] initWithApplicationDelegate:parent.appDelegate tripInstance:tripInstance trip:tripDetails.trip];
        vc.currentStopId = parent.stopId;
        [parent.navigationController pushViewController:vc animated:YES];
    }
}

@end




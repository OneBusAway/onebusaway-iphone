#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBAReportProblemWithTripViewController.h"

@implementation OBAReportProblemWithRecentTripsViewController

- (void) customSetup {
    self.showTitle = NO;
    self.showActions = NO;
    self.arrivalCellFactory.showServiceAlerts = NO;
    self.showServiceAlerts = NO;
    self.minutesBefore = 30;
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
            [self.appDelegate.modelService requestTripDetailsForTripInstance:tripInstance
                                                             completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                                                                 if(jsonData) {
                                                                     OBAEntryWithReferencesV2 * entry = jsonData;
                                                                     OBATripDetailsV2 * tripDetails = entry.entry;
                                                                     if( tripDetails ) {
                                                                         OBATripInstanceRef * tripInstance = tripDetails.tripInstance;
                                                                         OBAReportProblemWithTripViewController * vc = [[OBAReportProblemWithTripViewController alloc] initWithApplicationDelegate:self.appDelegate tripInstance:tripInstance trip:tripDetails.trip];
                                                                         vc.currentStopId = self.stopId;
                                                                         [self.navigationController pushViewController:vc animated:YES];
                                                                     }
                                                                     
                                                                 }
                                                                 
                                                             } progressBlock:nil];
        }
    }
}

@end
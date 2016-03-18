#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBAApplication.h"
#import "OBAClassicDepartureRow.h"

@interface OBAReportProblemWithRecentTripsViewController ()
@property(nonatomic,copy) NSString *stopID;
@end

@implementation OBAReportProblemWithRecentTripsViewController

- (instancetype)initWithStopID:(NSString*)stopID {
    self = [super init];

    if (self) {
        _stopID = [stopID copy];
        self.title = NSLocalizedString(@"Select a Trip", @"");
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[OBAApplication sharedApplication].modelService requestStopForID:self.stopID minutesBefore:30 minutesAfter:30].then(^(OBAArrivalsAndDeparturesForStopV2 *response) {

        [self populateTableFromArrivalsAndDeparturesModel:response];
    }).catch(^(NSError *error) {
        self.title = error.localizedDescription ?: NSLocalizedString(@"Error connecting", @"requestDidFail");
    });
}

- (void)populateTableFromArrivalsAndDeparturesModel:(OBAArrivalsAndDeparturesForStopV2*)result {
    NSMutableArray *departureRows = [NSMutableArray array];

    for (OBAArrivalAndDepartureV2 *dep in result.arrivalsAndDepartures) {
        NSString *dest = dep.tripHeadsign.capitalizedString;
        OBAClassicDepartureRow *row = [[OBAClassicDepartureRow alloc] initWithRouteName:dep.bestAvailableName destination:dest departsAt:[NSDate dateWithTimeIntervalSince1970:(dep.bestDepartureTime / 1000)] statusText:[dep statusText] departureStatus:[dep departureStatus] action:^{
            [self reportProblemWithTrip:dep.tripInstance];
        }];

        [departureRows addObject:row];
    }

    self.sections = @[[[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Report a Problem", @"") rows:departureRows]];
    [self.tableView reloadData];
}

- (void)reportProblemWithTrip:(OBATripInstanceRef*)tripInstance {

    [[OBAApplication sharedApplication].modelService requestTripDetailsForTripInstance:tripInstance].then(^(OBATripDetailsV2 *tripDetails) {
        OBAReportProblemWithTripViewController *vc = [[OBAReportProblemWithTripViewController alloc] initWithTripInstance:tripInstance trip:tripDetails.trip];
        vc.currentStopId = self.stopID;
        [self.navigationController pushViewController:vc animated:YES];
    }).catch(^(NSError *error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error Connecting", @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

@end
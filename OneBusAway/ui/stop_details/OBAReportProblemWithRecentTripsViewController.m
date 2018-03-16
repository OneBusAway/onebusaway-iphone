/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBAReportProblemWithTripViewController.h"
@import SVProgressHUD;
#import "OneBusAway-Swift.h"
#import "OBAReportProblemWithStopViewController.h"

@interface OBAReportProblemWithRecentTripsViewController ()
@property(nonatomic,strong) PromiseWrapper *stopArrivalsPromiseWrapper;
@property(nonatomic,strong) PromiseWrapper *tripDetailsPromiseWrapper;
@property(nonatomic,copy) NSString *stopID;
@property(nonatomic,strong) OBAArrivalsAndDeparturesForStopV2 *arrivalsAndDepartures;
@end

@implementation OBAReportProblemWithRecentTripsViewController

- (instancetype)initWithStopID:(NSString*)stopID {
    self = [super init];

    if (self) {
        _stopID = [stopID copy];
        self.title = NSLocalizedString(@"msg_report_problem",);
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    }
    return self;
}

- (void)dealloc {
    [self.stopArrivalsPromiseWrapper cancel];
    [self.tripDetailsPromiseWrapper cancel];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [SVProgressHUD show];
    self.stopArrivalsPromiseWrapper = [self.modelService requestStopArrivalsAndDeparturesWithID:self.stopID minutesBefore:30 minutesAfter:30];
    self.stopArrivalsPromiseWrapper.anyPromise.then(^(NetworkResponse *networkResponse) {
        OBAArrivalsAndDeparturesForStopV2 *response = networkResponse.object;
        self.arrivalsAndDepartures = response;
        [self populateTable];
    }).always(^{
        [SVProgressHUD dismiss];
    }).catch(^(NSError *error) {
        [AlertPresenter showError:error presentingController:self];
    });
}

- (void)populateTable {
    OBATableSection *stopSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_the_stop_itself",)];
    OBATableRow *theStopRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_report_problem_this_stop",) action:^(OBABaseRow *r2) {
        OBAReportProblemWithStopViewController * vc = [[OBAReportProblemWithStopViewController alloc] initWithStop:self.arrivalsAndDepartures.stop];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    theStopRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    stopSection.rows = @[theStopRow];

    NSMutableArray *departureRows = [NSMutableArray array];

    for (OBAArrivalAndDepartureV2 *dep in self.arrivalsAndDepartures.arrivalsAndDepartures) {
        OBADepartureRow *row = [[OBADepartureRow alloc] initWithAction:^(OBABaseRow *blockRow){
            [self reportProblemWithTrip:dep.tripInstance];
        }];

        OBAUpcomingDeparture *upcoming = [[OBAUpcomingDeparture alloc] initWithDepartureDate:dep.bestArrivalDepartureDate departureStatus:dep.departureStatus arrivalDepartureState:dep.arrivalDepartureState];
        row.upcomingDepartures = @[upcoming];

        row.attributedMiddleLine = [OBADepartureRow buildAttributedRoute:dep.bestAvailableName destination:dep.tripHeadsign.capitalizedString];
        row.attributedBottomLine = [OBADepartureCellHelpers attributedDepartureTimeWithStatusText:[OBADepartureCellHelpers statusTextForArrivalAndDeparture:dep] upcomingDeparture:upcoming];

        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        [departureRows addObject:row];
    }

    OBATableSection *departuresSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_vehicle_this_stop",) rows:departureRows];

    self.sections = @[stopSection, departuresSection];
    [self.tableView reloadData];
}

- (void)reportProblemWithTrip:(OBATripInstanceRef*)tripInstance {
    [SVProgressHUD show];

    self.tripDetailsPromiseWrapper = [self.modelService requestTripDetailsWithTripInstance:tripInstance];
    self.tripDetailsPromiseWrapper.anyPromise.then(^(NetworkResponse *response) {
        OBATripDetailsV2 *tripDetails = response.object;
        OBAReportProblemWithTripViewController *vc = [[OBAReportProblemWithTripViewController alloc] initWithTripInstance:tripInstance trip:tripDetails.trip];
        vc.currentStopId = self.stopID;
        [self.navigationController pushViewController:vc animated:YES];
    }).always(^{
        [SVProgressHUD dismiss];
    }).catch(^(NSError *error) {
        [AlertPresenter showError:error presentingController:self];
    });
}

#pragma mark - Lazy Loading

- (PromisedModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Actions

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

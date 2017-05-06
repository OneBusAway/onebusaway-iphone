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

#import "OBAVehicleDetailsController.h"
#import "OneBusAway-Swift.h"
@import SVProgressHUD;

@interface OBAVehicleDetailsController ()
@property(nonatomic,copy) NSString *vehicleId;
@property(nonatomic,strong) OBAVehicleStatusV2 *vehicleStatus;
@end

@implementation OBAVehicleDetailsController

- (id)initWithVehicleId:(NSString *)vehicleId {
    if (self = [super init]) {
        _vehicleId = [vehicleId copy];
        self.title = NSLocalizedString(@"msg_vehicle_details",);
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];

    [self reload];
}

- (void)reload {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [SVProgressHUD show];
    [self.modelService requestVehicleForID:self.vehicleId].then(^(OBAVehicleStatusV2 *vehicleStatus) {
        self.vehicleStatus = vehicleStatus;
        [self loadData];
    }).always(^{
        [SVProgressHUD dismiss];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }).catch(^(NSError *error) {
        [AlertPresenter showError:error];
    });
}

- (void)loadData {
    OBATableSection *vehicleDetails = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_vehicle_details_colon", @"OBASectionTypeVehicleDetails")];

    [vehicleDetails addRowWithBlock:^OBABaseRow *{
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"text_vehicle_colon_param",), self.vehicleStatus.vehicleId] action:nil];
        tableRow.style = UITableViewCellStyleSubtitle;
        tableRow.subtitle = [NSString stringWithFormat:NSLocalizedString(@"text_last_update_param",), [OBADateHelpers formatShortTimeNoDate:self.vehicleStatus.lastUpdate]];
        return tableRow;
    }];

    OBATableSection *activeTripDetails = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_active_trip_details_colon", @"OBASectionTypeTripDetails")];

    OBATripStatusV2 *tripStatus = self.vehicleStatus.tripStatus;

    // Trip route name and headsign
    [activeTripDetails addRowWithBlock:^OBABaseRow*{
        OBATripV2 *trip = tripStatus.activeTrip;
        OBARouteV2 *route = trip.route;
        NSString *rowTitle = [NSString stringWithFormat:@"%@ - %@", route.safeShortName, trip.tripHeadsign];
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:rowTitle action:nil];
        return row;
    }];

    // Schedule Deviation
    if (!tripStatus.frequency && tripStatus.scheduleDeviation != 0) {
        [activeTripDetails addRowWithBlock:^OBABaseRow *{
            return [[OBATableRow alloc] initWithTitle:tripStatus.formattedScheduleDeviation action:nil];
        }];
    }

    self.sections = @[vehicleDetails, activeTripDetails];
    [self.tableView reloadData];
}

#pragma mark - Lazily Loaded Properties

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

@end

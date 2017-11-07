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

#import "OBATripDetailsViewController.h"
@import SVProgressHUD;
#import "OneBusAway-Swift.h"
#import "OBATripScheduleMapViewController.h"
#import "OBATripScheduleListViewController.h"
#import "OBAReportProblemWithTripViewController.h"

@interface OBATripDetailsViewController ()
@property(nonatomic,strong) OBATripInstanceRef *tripInstance;
@property(nonatomic,strong) OBATripDetailsV2 *tripDetails;
@property(nonatomic,copy) NSString *currentStopId;
@end

@implementation OBATripDetailsViewController

- (id)initWithTripInstance:(OBATripInstanceRef *)tripInstance {
    if (self = [super init]) {
        _tripInstance = tripInstance;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadData)];

    [self reloadData];
}

- (void)reloadData {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [SVProgressHUD show];

    [self.modelService promiseTripDetailsFor:self.tripInstance].then(^(OBATripDetailsV2 *tripDetails) {
        self.tripDetails = tripDetails;
        [self buildSections];
    }).always(^{
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [SVProgressHUD dismiss];
    }).catch(^(NSError *error) {
        [AlertPresenter showError:error];
    });
}

- (void)buildSections {
    OBATripV2 *trip = self.tripDetails.trip;
    NSMutableArray *sections = [[NSMutableArray alloc] init];

    OBATableSection *titleSection = [[OBATableSection alloc] initWithTitle:nil];
    [sections addObject:titleSection];

    [titleSection addRowWithBlock:^OBABaseRow *{
        OBATableRow *row = [[OBATableRow alloc] initWithAction:nil];
        row.title = trip.asLabel;
        return row;
    }];

    if (self.tripDetails.status.predicted) {
        [titleSection addRowWithBlock:^OBABaseRow *{
            OBATableRow *row = [[OBATableRow alloc] initWithAction:nil];
            row.title = [self.class vehicleStatusLabelFromTripStatus:self.tripDetails.status];
            return row;
        }];
    }

    OBATableSection *tripScheduleSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_trip_schedule",)];
    [sections addObject:tripScheduleSection];

    [tripScheduleSection addRowWithBlock:^OBABaseRow *{
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_show_as_map",) action:^(OBABaseRow *r2){
            OBATripScheduleMapViewController *vc = [[OBATripScheduleMapViewController alloc] init];
            vc.tripInstance = self.tripInstance;
            vc.tripDetails = self.tripDetails;
            vc.currentStopId = self.currentStopId;
            [self.navigationController pushViewController:vc animated:YES];
        }];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return row;
    }];

    [tripScheduleSection addRowWithBlock:^OBABaseRow *{
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_show_as_list",) action:^(OBABaseRow *r2){
            OBATripScheduleListViewController *vc = [[OBATripScheduleListViewController alloc] initWithTripInstance:self.tripInstance];
            vc.tripDetails = self.tripDetails;
            vc.currentStopId = self.currentStopId;
            [self.navigationController pushViewController:vc animated:YES];
        }];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return row;
    }];

    OBATableSection *reportProblemSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_report_problem",)];
    [sections addObject:reportProblemSection];
    [reportProblemSection addRowWithBlock:^OBABaseRow *{
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_mayus_report_problem_this_trip",) action:^(OBABaseRow *r2) {
            OBAReportProblemWithTripViewController *vc = [[OBAReportProblemWithTripViewController alloc] initWithTripInstance:self.tripInstance trip:self.tripDetails.trip];
            vc.currentStopId = self.currentStopId;
            [self.navigationController pushViewController:vc animated:YES];
        }];
        tableRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return tableRow;
    }];

    self.sections = sections;
    [self.tableView reloadData];
}

#pragma mark - Lazily Loaded Properties

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (PromisedModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Private

+ (NSString*)vehicleStatusLabelFromTripStatus:(OBATripStatusV2*)status {
    NSInteger scheduleDeviation = status.scheduleDeviation / 60;
    NSString *label = @"";

    if (scheduleDeviation <= -2) label = [NSString stringWithFormat:@"%ld %@", (long)(-scheduleDeviation), NSLocalizedString(@"msg_minutes_early", @"scheduleDeviation <= -2")];
    else if (scheduleDeviation < 2) label = NSLocalizedString(@"msg_on_time", @"scheduleDeviation < 2");
    else label = [NSString stringWithFormat:@"%ld %@", (long)scheduleDeviation, NSLocalizedString(@"msg_minutes_late", @"scheduleDeviation >= 2")];

    return [NSString stringWithFormat:@"%@ # %@ - %@", NSLocalizedString(@"msg_mayus_vehicle", @"cell.statusLabel.text"), status.vehicleId, label];
}

@end

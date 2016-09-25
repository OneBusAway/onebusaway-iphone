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

#import "OBAReportProblemViewController.h"
#import "OBAReportProblemWithStopViewController.h"
#import "OBAReportProblemWithRecentTripsViewController.h"

@interface OBAReportProblemViewController ()
@property(nonatomic,strong) OBAStopV2 *stop;
@end

@implementation OBAReportProblemViewController

- (instancetype)initWithStop:(OBAStopV2*)stop {
    if (self = [super init]) {
        _stop = stop;
        self.title = NSLocalizedString(@"Report a Problem",);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    OBATableRow *stop = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"The Stop Itself",) action:^{
        OBAReportProblemWithStopViewController * vc = [[OBAReportProblemWithStopViewController alloc] initWithStop:self.stop];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    stop.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableRow *vehicle = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"A Vehicle at this Stop",) action:^{
        OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithStopID:self.stop.stopId];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    vehicle.subtitle = NSLocalizedString(@"For example: a bus, train, water taxi, etc.",);
    vehicle.style = UITableViewCellStyleSubtitle;
    vehicle.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"The Problem is With",) rows:@[stop, vehicle]];
    self.sections = @[section];
    [self.tableView reloadData];
}

@end

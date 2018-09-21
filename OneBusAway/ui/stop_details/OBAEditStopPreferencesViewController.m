/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAEditStopPreferencesViewController.h"
#import "OBAAnalytics.h"

@interface OBAEditStopPreferencesViewController ()
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) OBAStopV2 *stop;
@property(nonatomic,strong) OBAStopPreferencesV2 *preferences;
@end

@implementation OBAEditStopPreferencesViewController

- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO stop:(OBAStopV2*)stop {
    self = [super init];

    if (self) {
        _stop = stop;
        _modelDAO = modelDAO;
        _preferences = [_modelDAO stopPreferencesForStopWithId:_stop.stopId];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"msg_sort_and_filter_routes", @"Title for the Edit Stop Preferences Controller");

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];

    [self loadData];
}

#pragma mark - Actions

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save {
    [self.modelDAO setStopPreferences:self.preferences forStopWithId:self.stop.stopId];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Static Table View

- (void)loadData {
    OBATableSection *sortSection = [self buildSortSection];
    OBATableSection *filterSection = [self buildFilterSection];

    self.sections = @[sortSection, filterSection];
    [self.tableView reloadData];
}

- (OBATableSection*)buildSortSection {
    OBATableSection *sortSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_sorting",)];
    OBATableRow *row = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_sort_by_time",) action:^(OBABaseRow *r2) {
        [self.preferences toggleTripSorting];
        [self loadData];
    }];
    if (self.preferences.sortTripsByType == OBASortTripsByDepartureTimeV2) {
        row.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    [sortSection addRow:row];
    row = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_sort_by_route",) action:^(OBABaseRow *r2) {
        [self.preferences toggleTripSorting];
        [self loadData];
    }];
    if (self.preferences.sortTripsByType == OBASortTripsByRouteNameV2) {
        row.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    [sortSection addRow:row];

    return sortSection;
}

- (OBATableSection*)buildFilterSection {
    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_routes",)];

    for (OBARouteV2 *route in [self.stop.routes sortedArrayUsingSelector:@selector(compareUsingName:)]) {
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:route.safeShortName action:^(OBABaseRow *r2) {
            [self.preferences toggleRouteID:route.routeId];
            [self loadData];
        }];
        BOOL checked = [self.preferences isRouteIdEnabled:route.routeId];
        row.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        [section addRow:row];
    }

    return section;
}

@end

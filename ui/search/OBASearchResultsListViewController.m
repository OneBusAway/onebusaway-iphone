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

#import "OBASearchResultsListViewController.h"
#import "OBAStopViewController.h"
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBARouteV2.h>
#import <OBAKit/OBAAgencyWithCoverageV2.h>
#import <OBAKit/OBASearchResult.h>
#import "OBAApplicationDelegate.h"
#import "OBASearchController.h"

@implementation OBASearchResultsListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.title = NSLocalizedString(@"Nearby", @"");
        self.emptyDataSetTitle = NSLocalizedString(@"No Results Found", @"");
        self.emptyDataSetDescription = NSLocalizedString(@"No results were found for the searched area. Zoom out or move the map around to choose a different area.", @"");

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataUpdated:) name:OBASearchControllerDidUpdateNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBASearchControllerDidUpdateNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStyleDone target:self action:@selector(dismissModal)];

    [self loadData];
}

#pragma mark - Actions

- (void)dismissModal {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Settrs

- (void)setResult:(OBASearchResult *)result {
    _result = result;
    [self loadData];
}

#pragma mark - Notifications

- (void)dataUpdated:(NSNotification*)note {
    self.result = note.userInfo[OBASearchControllerUserInfoDataKey];
}

#pragma mark - Table Data

- (void)loadData {
    NSMutableArray *rows = [NSMutableArray array];

    for (id obj in self.result.values) {
        OBATableRow *tableRow = [[OBATableRow alloc] init];
        tableRow.style = UITableViewCellStyleSubtitle;
        tableRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        switch (self.result.searchType) {
            case OBASearchTypeRegion:
            case OBASearchTypePlacemark:
            case OBASearchTypeStopId:
            case OBASearchTypeRouteStops: {
                OBAStopV2 *stop = obj;
                tableRow.title = stop.name;
                [tableRow setAction:^(OBABaseRow *row) {
                    OBAStopViewController *vc = [[OBAStopViewController alloc] initWithStopID:stop.stopId];
                    [self.navigationController pushViewController:vc animated:YES];
                }];
                tableRow.subtitle = stop.subtitle;
                break;
            }
            case OBASearchTypeRoute: {
                OBARouteV2 *route = obj;
                tableRow.title = route.fullRouteName;
                tableRow.subtitle = route.agency.name;
                [tableRow setAction:^(OBABaseRow* row){
                    OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchRouteStops:route.routeId];
                    [APP_DELEGATE navigateToTarget:target];
                    [self dismissModal];
                }];
                break;
            }
            case OBASearchTypeAddress: {
                OBAPlacemark *placemark = obj;
                tableRow.title = placemark.title;
                tableRow.style = UITableViewCellStyleDefault;
                [tableRow setAction:^(OBABaseRow *row){
                    OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchPlacemark:placemark];
                    [APP_DELEGATE navigateToTarget:target];
                    [self dismissModal];
                }];
                break;
            }
            case OBASearchTypeAgenciesWithCoverage: {
                // There's no action to take when an agency is selected.
                // hence the lack of a -setAction: call.
                OBAAgencyWithCoverageV2 * awc = obj;
                tableRow.style = UITableViewCellStyleDefault;
                tableRow.title = awc.agency.name;
                tableRow.accessoryType = UITableViewCellAccessoryNone;
                break;
            }
            default: {
                // no-op.
            }
        }
        [rows addObject:tableRow];
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:rows];
    self.sections = @[section];
    [self.tableView reloadData];
}

#pragma mark - Private

+ (nullable NSString*)titleFromSearchResult:(OBASearchResult*)result {
    switch (result.searchType) {
        case OBASearchTypeNone:
            return NSLocalizedString(@"No Results",@"OBASearchTypeNone");
        case OBASearchTypeRegion:
        case OBASearchTypePlacemark:
        case OBASearchTypeStopId:
        case OBASearchTypeRouteStops:
            return NSLocalizedString(@"Stops",@"OBASearchTypeRouteStops");
        case OBASearchTypeRoute:
            return NSLocalizedString(@"Routes",@"OBASearchTypeRoute");
        case OBASearchTypeAddress:
            return NSLocalizedString(@"Places",@"OBASearchTypeAddress");
        case OBASearchTypeAgenciesWithCoverage:
            return NSLocalizedString(@"Agencies",@"OBASearchTypeAgenciesWithCoverage");
        default:
            return nil;
    }
}

@end

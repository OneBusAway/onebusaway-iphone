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

#import "OBARecentStopsViewController.h"
#import "OBAStopViewController.h"
#import "OBAArrivalAndDepartureViewController.h"

@implementation OBARecentStopsViewController

- (id)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Recent", @"Recent stops tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Recent"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"Recent_Selected"];
        self.emptyDataSetTitle = NSLocalizedString(@"No Recent Stops", @"");
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear Stops", @"") style:UIBarButtonItemStylePlain target:self action:@selector(clearRecentList)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    OBALogFunction();

    [self.modelDAO clearSharedTripsOlderThan24Hours];

    [self reloadData];
}

#pragma mark - Actions

- (void)clearRecentList {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Clear Recent Stops", @"") message:NSLocalizedString(@"Are you sure you want to clear your recent stops?", @"") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Clear Stops", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.modelDAO clearMostRecentStops];
        [self.modelDAO clearSharedTrips];
        [self reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Lazy Loading

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

#pragma mark - Data Loading

- (void)buildSections {
    NSMutableArray *sections = [NSMutableArray new];

    OBATableSection *sharedTripsSection = [self buildSharedTripsSection];
    if (sharedTripsSection) {
        [sections addObject:sharedTripsSection];
    }

    OBATableSection *recentStopsSection = [self buildRecentStopsSection];
    if (recentStopsSection) {
        [sections addObject:recentStopsSection];
    }

    self.sections = sections;
}

- (void)reloadData {
    [self buildSections];
    [self.tableView reloadData];
}

- (nullable OBATableSection*)buildSharedTripsSection {
    NSArray<OBATripDeepLink *> *sharedTrips = self.modelDAO.sharedTrips;

    if (sharedTrips.count == 0) {
        return nil;
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Shared Trips", @"Section title for the shared trips section in the 'Recent' tab.")];

    for (OBATripDeepLink *link in sharedTrips) {
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:link.name action:^{
            [self displayTripDeepLink:link animated:YES];
        }];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        [row setDeleteModel:^(OBABaseRow *r) {
            [self.modelDAO removeSharedTrip:link];
        }];

        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:OBAStrings.delete handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [self deleteRowAtIndexPath:indexPath];
        }];
        [row setRowActions:@[deleteAction]];

        [section addRow:row];
    }

    return section;
}

- (nullable OBATableSection*)buildRecentStopsSection {

    if (self.modelDAO.mostRecentStops.count == 0) {
        return nil;
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Recent Stops",)];

    for (OBAStopAccessEventV2* stop in self.modelDAO.mostRecentStops) {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:stop.title action:^{
            [self showStopViewControllerWithStopID:stop.stopIds[0]];
        }];
        tableRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        tableRow.style = UITableViewCellStyleSubtitle;
        tableRow.subtitle = stop.subtitle;

        [tableRow setDeleteModel:^(OBABaseRow *r) {
            [self.modelDAO removeRecentStop:stop];
        }];

        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:OBAStrings.delete handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [self deleteRowAtIndexPath:indexPath];
        }];
        [tableRow setRowActions:@[deleteAction]];

        [section addRow:tableRow];
    }
    return section;
}

- (void)showStopViewControllerWithStopID:(NSString*)stopID {
    OBAStopViewController *vc = [[OBAStopViewController alloc] initWithStopID:stopID];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteRowAtIndexPath:indexPath];
    }
}

#pragma mark - Deep Links

- (void)displayTripDeepLink:(OBATripDeepLink*)link animated:(BOOL)animated {
    OBAArrivalAndDepartureViewController *controller = [[OBAArrivalAndDepartureViewController alloc] initWithTripDeepLink:link];
    [self.navigationController pushViewController:controller animated:animated];
}

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget navigationTarget:OBANavigationTargetTypeRecentStops];
}

- (void)setNavigationTarget:(OBANavigationTarget *)target {
    if ([target.object isKindOfClass:[OBATripDeepLink class]]) {
        [self displayTripDeepLink:target.object animated:NO];
    }
    else if (target.parameters[OBAStopIDNavigationTargetParameter]) {
        NSString *stopID = target.parameters[OBAStopIDNavigationTargetParameter];
        [self showStopViewControllerWithStopID:stopID];
    }
    else {
        DDLogError(@"Unhandled object type (%@) from OBANavigationTarget: %@", target.object, target);
    }
}

@end

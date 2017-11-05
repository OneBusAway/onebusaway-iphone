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
        self.title = NSLocalizedString(@"msg_recent", @"Recent stops tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Recent"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"Recent_Selected"];
        self.emptyDataSetTitle = NSLocalizedString(@"msg_no_recent_stops", @"");
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"msg_clear_stops", @"") style:UIBarButtonItemStylePlain target:self action:@selector(clearRecentList)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    OBALogFunction();

    [self.modelDAO clearSharedTripsOlderThan24Hours];
    [self.modelDAO clearExpiredAlarms];

    [self reloadData];
}

#pragma mark - Actions

- (void)clearRecentList {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_clear_recent_stops", @"") message:NSLocalizedString(@"msg_ask_clear_recent_stops", @"") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_clear_stops", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
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

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Data Loading

- (void)buildSections {
    NSMutableArray *sections = [NSMutableArray new];

    OBATableSection *alarmsSection = [self buildAlarmsSection];
    if (alarmsSection) {
        [sections addObject:alarmsSection];
    }

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

- (nullable OBATableSection*)buildAlarmsSection {
    NSArray<OBAAlarm*> *alarms = self.modelDAO.alarms;

    if (alarms.count == 0) {
        return nil;
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"recent_stops.alarms_section_title", @"Title of the Alarms section in the Recent Stops controller")];

    for (OBAAlarm *alarm in alarms) {
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:alarm.title action:^(OBABaseRow *r2){
            OBAArrivalAndDepartureViewController *controller = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDepartureConvertible:alarm];
            [self.navigationController pushViewController:controller animated:YES];
        }];
        NSInteger minutes = (NSInteger)(alarm.timeIntervalBeforeDeparture / 60);
        NSString *formattedTime = [OBADateHelpers formatShortTimeNoDate:alarm.estimatedDeparture];

        row.subtitle = [NSString stringWithFormat:NSLocalizedString(@"recent_stops.alarms.subtitle", @"e.g. <10> minutes before <5:02PM> departure (scheduled)"), @(minutes), formattedTime];
        row.style = UITableViewCellStyleSubtitle;
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        [row setDeleteModel:^(OBABaseRow *r) {
            NSURLRequest *request = [self.modelService.obaJsonDataSource requestWithURL:alarm.alarmURL HTTPMethod:@"DELETE"];
            [self.modelService.obaJsonDataSource performRequest:request completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
                // nop?
            }];
            [self.modelDAO removeAlarmWithKey:alarm.alarmKey];
        }];

        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:OBAStrings.delete handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [self deleteRowAtIndexPath:indexPath];
        }];
        [row setRowActions:@[deleteAction]];

        [section addRow:row];
    }

    return section;
}

- (nullable OBATableSection*)buildSharedTripsSection {
    NSArray<OBATripDeepLink *> *sharedTrips = self.modelDAO.sharedTrips;

    if (sharedTrips.count == 0) {
        return nil;
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_shared_trips", @"Section title for the shared trips section in the 'Recent' tab.")];

    for (OBATripDeepLink *link in sharedTrips) {
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:link.name action:^(OBABaseRow *r2){
            OBAArrivalAndDepartureViewController *controller = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDepartureConvertible:link];
            [self.navigationController pushViewController:controller animated:YES];
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

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_recent_stops",)];

    for (OBAStopAccessEventV2* stop in self.modelDAO.mostRecentStops) {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:stop.title action:^(OBABaseRow *r2){
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

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget navigationTarget:OBANavigationTargetTypeRecentStops];
}

- (void)setNavigationTarget:(OBANavigationTarget *)target {
    if ([target.object conformsToProtocol:@protocol(OBAArrivalAndDepartureConvertible)]) {
        OBAArrivalAndDepartureViewController *controller = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDepartureConvertible:target.object];
        [self.navigationController pushViewController:controller animated:YES];
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

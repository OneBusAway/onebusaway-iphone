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
#import <OBAKit/OBAKit.h>
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import "OBAStopViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"

@interface OBARecentStopsViewController ()<DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@end

@implementation OBARecentStopsViewController

- (id)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Recent", @"Recent stops tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Clock"];
        self.emptyDataSetTitle = NSLocalizedString(@"No Recent Stops", @"");
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear Stops", @"") style:UIBarButtonItemStylePlain target:self action:@selector(clearRecentList)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self reloadData];
}

#pragma mark - Actions

- (void)clearRecentList {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Clear Recent Stops", @"") message:NSLocalizedString(@"Are you sure you want to clear your recent stops?", @"") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Clear Stops", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.modelDAO clearMostRecentStops];
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

- (void)reloadData {

    OBATableSection *section = [[OBATableSection alloc] init];

    for (OBAStopAccessEventV2* stop in self.modelDAO.mostRecentStops) {
        [section addRowWithBlock:^OBABaseRow*{
            OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:stop.title action:^{
                OBAStopViewController *vc = [[OBAStopViewController alloc] initWithStopID:stop.stopIds[0]];
                [self.navigationController pushViewController:vc animated:YES];
            }];
            tableRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            tableRow.style = UITableViewCellStyleSubtitle;
            tableRow.subtitle = stop.subtitle;
            return tableRow;
        }];
    }

    self.sections = @[section];
    [self.tableView reloadData];
}

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeRecentStops];
}

@end

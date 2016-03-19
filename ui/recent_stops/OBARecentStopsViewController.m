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
#import "OBAStopAccessEventV2.h"
#import "OBAStopViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"
#import "OBAApplication.h"

@interface OBARecentStopsViewController ()<DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@end

@implementation OBARecentStopsViewController

- (id)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Recent", @"Recent stops tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Clock"];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up the empty data set UI.
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)reloadData {

    OBATableSection *section = [[OBATableSection alloc] init];

    for (OBAStopAccessEventV2* stop in [OBAApplication sharedApplication].modelDao.mostRecentStops) {

        [section addRow:^OBABaseRow*{
            OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:stop.title action:^{
                UIViewController *vc = [OBAStopViewController stopControllerWithStopID:stop.stopIds[0]];
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

#pragma mark - DZNEmptyDataSet

#pragma mark TODO - This is duplicated from the Bookmarks controller. DRY up!

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = NSLocalizedString(@"No Recent Stops", @"");

    NSDictionary *attributes = @{NSFontAttributeName: [OBATheme titleFont],
                                 NSForegroundColorAttributeName: [OBATheme darkDisabledColor]};

    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    // Totally arbitrary value. It just 'looks right'.
    return -44;
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeRecentStops];
}

@end

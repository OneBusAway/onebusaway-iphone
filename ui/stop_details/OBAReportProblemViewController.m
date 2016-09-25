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
#import <OBAKit/OBAKit.h>
#import "OBAReportProblemWithStopViewController.h"
#import "OBAReportProblemWithRecentTripsViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"

@implementation OBAReportProblemViewController

#pragma mark -
#pragma mark Initialization

- (id) initWithStop:(OBAStopV2*)stop {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _stop = stop;
        
        self.navigationItem.title = NSLocalizedString(@"Report a Problem",@"self.navigationItem.title");
        
        UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Report",@"UIBarButtonItem initWithTitle") style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = item;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self hideEmptySeparators];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    view.backgroundColor = [OBATheme OBAGreenBackground];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
    title.font = [OBATheme bodyFont];
    title.backgroundColor = [UIColor clearColor];
    title.text = NSLocalizedString(@"The problem is with:",@"tableView titleForHeaderInSection");
    [view addSubview:title];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"identifier"];            
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = [OBATheme bodyFont];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"The stop itself",@"case 0 cell.textLabel.text");
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"A bus/train/etc at this stop",@"case 1 cell.textLabel.text");
            break;
        default:
            break;
    }
    return cell;            
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            OBAReportProblemWithStopViewController * vc = [[OBAReportProblemWithStopViewController alloc] initWithStop:_stop];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 1: {
            OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithStopID:_stop.stopId];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default:
            break;
    }
}

@end


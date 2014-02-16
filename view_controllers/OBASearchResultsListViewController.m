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
#import "OBALogger.h"
#import "OBARouteV2.h"
#import "OBAAgencyWithCoverageV2.h"
#import "OBASearchResultsMapViewController.h"
#import "OBAStopViewController.h"
#import "UITableViewController+oba_Additions.h"


@interface OBASearchResultsListViewController ()
- (UITableViewCell*)tableView:(UITableView *)tableView zeroCountCellWithKind:(NSString*)kind;
- (void) reloadData;
- (NSString*) getStopDetail:(OBAStopV2*) stop;
- (NSString*) getRouteText:(OBARouteV2*) route;
@end


@implementation OBASearchResultsListViewController

- (id) initWithContext:(OBAApplicationDelegate*)appDelegate searchControllerResult:(OBASearchResult*)result {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.isModal = NO;
        _appDelegate = appDelegate;
        self.result = result;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.isModal) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map"] style:UIBarButtonItemStyleBordered target:self action:@selector(dismissModal)];
    }

    CGFloat height = 2.f * CGRectGetHeight(self.view.frame);
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, -0.25f * height, 1, height)];
    line.backgroundColor = [UIColor grayColor];
    [self.view addSubview:line];
    [self hideEmptySeparators];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Actions

- (void)dismissModal {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Table view methods

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (_result.searchType) {
        case OBASearchTypeNone:
            return 1;
        case OBASearchTypeRegion:
        case OBASearchTypePlacemark:
        case OBASearchTypeStopId:            
        case OBASearchTypeRouteStops:
        case OBASearchTypeRoute:            
        case OBASearchTypeAddress:
        case OBASearchTypeAgenciesWithCoverage:
            return [_result count] == 0 ? 1 : [_result count];
        default:
            return 0;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (_result.searchType) {
        case OBASearchTypeNone: {
            UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
            cell.textLabel.text = NSLocalizedString(@"No results for current region",@"OBASearchTypeNone text");
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        case OBASearchTypeRegion:
        case OBASearchTypePlacemark:
        case OBASearchTypeStopId:            
        case OBASearchTypeRouteStops: {
            if (self.result.count == 0) {
                return [self tableView:tableView zeroCountCellWithKind:NSLocalizedString(@"stops", @"stops warnign")];
            }
            UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
            OBAStopV2 * stop = (_result.values)[indexPath.row];
            cell.textLabel.text = stop.name;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.text = [self getStopDetail:stop];
            return cell;
        }
        case OBASearchTypeRoute: {
            if (self.result.count == 0) {
                return [self tableView:tableView zeroCountCellWithKind:NSLocalizedString(@"routes", @"routes warnign")];
            }
            UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
            OBARouteV2 * route = (_result.values)[indexPath.row];
            OBAAgencyV2 * agency = route.agency;
            cell.textLabel.text = [self getRouteText:route];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.text = agency.name;
            return cell;
        }
        case OBASearchTypeAddress: {
            if (self.result.count == 0) {
                return [self tableView:tableView zeroCountCellWithKind:NSLocalizedString(@"places", @"places warnign")];
            }
            UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
            OBAPlacemark * placemark = (_result.values)[indexPath.row];
            cell.textLabel.text = [placemark title];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            return cell;
        }
        case OBASearchTypeAgenciesWithCoverage: {
            if (self.result.count == 0) {
                return [self tableView:tableView zeroCountCellWithKind:NSLocalizedString(@"agencies", @"agencies warnign")];
            }
            UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
            OBAAgencyWithCoverageV2 * awc = (_result.values)[indexPath.row];
            OBAAgencyV2 * agency = awc.agency;
            cell.textLabel.text = agency.name;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone; // Change once agencies can be selected.
            return cell;
        }
        default:
            
            break;
    }
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.text = NSLocalizedString(@"Unknown search results",@"_result.searchType");
    return cell;
}

- (UITableViewCell*)tableView:(UITableView *)tableView zeroCountCellWithKind:(NSString*)kind
{
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"No %@ at this location", @"No {kind} at this location"), kind];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (_result.searchType) {
        case OBASearchTypeNone: {
            break;
        }
        case OBASearchTypeRegion:
        case OBASearchTypePlacemark:
        case OBASearchTypeStopId:            
        case OBASearchTypeRouteStops: {
            if (self.result.count == 0) break;
            OBAStopV2 * stop = (_result.values)[indexPath.row];
            OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationDelegate:_appDelegate stopId:stop.stopId];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case OBASearchTypeRoute: {
            if (self.result.count == 0) break;
            OBARouteV2 * route = (_result.values)[indexPath.row];
            OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchRouteStops:route.routeId];
            [_appDelegate navigateToTarget:target];
            [self dismissModal];
            break;
        }
        case OBASearchTypeAddress: {
            if (self.result.count == 0) break;
            OBAPlacemark * placemark = (_result.values)[indexPath.row];
            OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchPlacemark:placemark];
            [_appDelegate navigateToTarget:target];
            [self dismissModal];
            break;
        }
        case OBASearchTypeAgenciesWithCoverage: {
            if (self.result.count == 0) break;
            //OBAAgencyWithCoverage * awc = [_result.agenciesWithCoverage objectAtIndex:indexPath.row];
            //OBAAgency * agency = awc.agency;
            // When agencies can be selected, make sure to change their cell's selectionStyle above
        }
        default:            
            break;
    }    
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeSearchResults];
}

- (void) reloadData {
    
    switch (_result.searchType) {
        case OBASearchTypeNone:
            self.navigationItem.title = NSLocalizedString(@"No results",@"OBASearchTypeNone");
            break;
        case OBASearchTypeRegion:
        case OBASearchTypePlacemark:
        case OBASearchTypeStopId:            
        case OBASearchTypeRouteStops:
            self.navigationItem.title = NSLocalizedString(@"Stops",@"OBASearchTypeRouteStops");
            break;
        case OBASearchTypeRoute:        
            self.navigationItem.title = NSLocalizedString(@"Routes",@"OBASearchTypeRoute");
            break;
        case OBASearchTypeAddress:
            self.navigationItem.title = NSLocalizedString(@"Places",@"OBASearchTypeAddress");
            break;
        case OBASearchTypeAgenciesWithCoverage:
            self.navigationItem.title = NSLocalizedString(@"Agencies",@"OBASearchTypeAgenciesWithCoverage");
            break;
        default:            
            break;
    }
        
    [self.tableView reloadData];
}

- (NSString*) getStopDetail:(OBAStopV2*) stop {
    
    NSMutableString * label = [NSMutableString string];
    
    if( stop.direction )
        [label appendFormat:@"%@ %@ - ",stop.direction,NSLocalizedString(@"bound",@"stop.direction label")];
    
    [label appendString:NSLocalizedString(@"Routes: ",@"label")];
    [label appendString:[stop routeNamesAsString]];
    return label;
}

- (NSString*) getRouteText:(OBARouteV2*) route {
    NSMutableArray *nameArray = [NSMutableArray array];
    if (route.shortName) {
        [nameArray addObject:route.shortName];
    }
    if (route.longName) {
        [nameArray addObject:route.longName];
    }
    
    return [nameArray componentsJoinedByString:@" - "];
}

@end

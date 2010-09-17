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
#import "OBAUIKit.h"
#import "OBAUITableViewCell.h"
#import "OBASearchResultsMapViewController.h"
#import "OBAStopViewController.h"


@interface OBASearchResultsListViewController (Private)

- (void) reloadData;
- (NSString*) getStopDetail:(OBAStopV2*) stop;

@end


@implementation OBASearchResultsListViewController

- (id) initWithContext:(OBAApplicationContext*)appContext searchControllerResult:(OBASearchControllerResult*)result {
	
	// Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [appContext retain];
		_result = [result retain];
	}
	return self;
}


- (void)dealloc {
	[_appContext release];
	[_result release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (_result.searchType) {
		case OBASearchControllerSearchTypeNone:
			return 0;
		case OBASearchControllerSearchTypeRegion:
		case OBASearchControllerSearchTypePlacemark:
		case OBASearchControllerSearchTypeStopId:			
		case OBASearchControllerSearchTypeRouteStops:
		case OBASearchControllerSearchTypeRoute:			
		case OBASearchControllerSearchTypeAddress:
		case OBASearchControllerSearchTypeAgenciesWithCoverage:
			return [_result count];
		default:
			return 0;
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	switch (_result.searchType) {
		case OBASearchControllerSearchTypeNone: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
			cell.textLabel.text = @"No search results";
			return cell;
		}
		case OBASearchControllerSearchTypeRegion:
		case OBASearchControllerSearchTypePlacemark:
		case OBASearchControllerSearchTypeStopId:			
		case OBASearchControllerSearchTypeRouteStops: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
			OBAStopV2 * stop = [_result.values objectAtIndex:indexPath.row];
			cell.textLabel.text = stop.name;
			cell.textLabel.adjustsFontSizeToFitWidth = TRUE;
			cell.detailTextLabel.text = [self getStopDetail:stop];
			return cell;
		}
		case OBASearchControllerSearchTypeRoute: {		
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
			OBARouteV2 * route = [_result.values objectAtIndex:indexPath.row];
			OBAAgencyV2 * agency = route.agency;
			cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",route.shortName,route.longName];
			cell.textLabel.adjustsFontSizeToFitWidth = TRUE;
			cell.detailTextLabel.text = agency.name;
			return cell;
		}
		case OBASearchControllerSearchTypeAddress: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
			OBAPlacemark * placemark = [_result.values objectAtIndex:indexPath.row];
			cell.textLabel.text = [placemark title];
			cell.textLabel.adjustsFontSizeToFitWidth = TRUE;
			return cell;
		}
		case OBASearchControllerSearchTypeAgenciesWithCoverage: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
			OBAAgencyWithCoverageV2 * awc = [_result.values objectAtIndex:indexPath.row];
			OBAAgencyV2 * agency = awc.agency;
			cell.textLabel.text = agency.name;
			cell.textLabel.adjustsFontSizeToFitWidth = TRUE;
			cell.selectionStyle = UITableViewCellSelectionStyleNone; // Change once agencies can be selected.
			return cell;
		}
		default:
			
			break;
	}
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.text = @"Unknown search results";
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (_result.searchType) {
		case OBASearchControllerSearchTypeNone: {
			break;
		}
		case OBASearchControllerSearchTypeRegion:
		case OBASearchControllerSearchTypePlacemark:
		case OBASearchControllerSearchTypeStopId:			
		case OBASearchControllerSearchTypeRouteStops: {
			
			OBAStopV2 * stop = [_result.values objectAtIndex:indexPath.row];
			OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationContext:_appContext stopId:stop.stopId];
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
		case OBASearchControllerSearchTypeRoute: {		
			OBARouteV2 * route = [_result.values objectAtIndex:indexPath.row];
			OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchRouteStops:route.routeId];
			[_appContext navigateToTarget:target];
			break;
		}
		case OBASearchControllerSearchTypeAddress: {
			OBAPlacemark * placemark = [_result.values objectAtIndex:indexPath.row];
			OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchPlacemark:placemark];
			[_appContext navigateToTarget:target];
			break;
		}
		case OBASearchControllerSearchTypeAgenciesWithCoverage: {
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

@end

@implementation OBASearchResultsListViewController (Private)

- (void) reloadData {
	
	switch (_result.searchType) {
		case OBASearchControllerSearchTypeNone:
			self.navigationItem.title = @"";
			break;
		case OBASearchControllerSearchTypeRegion:
		case OBASearchControllerSearchTypePlacemark:
		case OBASearchControllerSearchTypeStopId:			
		case OBASearchControllerSearchTypeRouteStops:
			self.navigationItem.title = @"Stops";
			break;
		case OBASearchControllerSearchTypeRoute:		
			self.navigationItem.title = @"Routes";
			break;
		case OBASearchControllerSearchTypeAddress:
			self.navigationItem.title = @"Places";
			break;
		case OBASearchControllerSearchTypeAgenciesWithCoverage:
			self.navigationItem.title = @"Agencies";
			break;
		default:			
			break;
	}
		
	[self.tableView reloadData];
}

- (NSString*) getStopDetail:(OBAStopV2*) stop {
	
	NSMutableString * label = [NSMutableString string];
	
	if( stop.direction )
		[label appendFormat:@"%@ bound - ",stop.direction];
	
	[label appendString:@"Routes: "];
	[label appendString:[stop routeNamesAsString]];
	return label;
}

@end



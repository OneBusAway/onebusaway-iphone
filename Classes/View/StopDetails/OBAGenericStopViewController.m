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
 * See the License for the specific languOBAStopSectionTypeage governing permissions and
 * limitations under the License.
 */

#import "OBAGenericStopViewController.h"
#import "OBALogger.h"

#import "OBAUIKit.h"

#import "OBAUITableViewCell.h"
#import "OBAStopTableViewCell.h"
#import "OBAArrivalEntryTableViewCell.h"

#import "OBAProgressIndicatorView.h"

#import "OBAPresentation.h"

#import "OBAStopPreferences.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBAEditStopPreferencesViewController.h"
#import "OBAArrivalAndDepartureViewController.h"
#import "OBATripDetailsViewController.h"
#import "OBAReportProblemViewController.h"

#import "OBASearchController.h"
#import "OBASphericalGeometryLibrary.h"

#import "UIDeviceExtensions.h"


static const double kNearbyStopRadius = 200;

	
@interface OBAGenericStopViewController (Private)

// Override point for extension classes
- (void) customSetup;

- (void) refresh;
- (void) clearPendingRequest;
- (void) didRefreshBegin;
- (void) didRefreshEnd;


- (NSUInteger) sectionIndexForSectionType:(OBAStopSectionType)section;

- (UITableViewCell*) tableView:(UITableView*)tableView stopCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView serviceAlertCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView predictedArrivalCellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)determineFilterTypeCellText:(UITableViewCell*)filterTypeCell filteringEnabled:(bool)filteringEnabled;
- (UITableViewCell*) tableView:(UITableView*)tableView filterCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectTripRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath;

- (void) reloadData;

@end


@implementation OBAGenericStopViewController

@synthesize appContext = _appContext;
@synthesize stopId = _stopId;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {

	if (self = [super initWithStyle:UITableViewStyleGrouped]) {

		_appContext = [appContext retain];
		
		_minutesBefore = 5;
		_minutesAfter = 35;
		
		_showTitle = TRUE;
		_showServiceAlerts = TRUE;
		_showActions = TRUE;
		
		_arrivalCellFactory = [[OBAArrivalEntryTableViewCellFactory alloc] initWithAppContext:_appContext tableView:self.tableView];
		_arrivalCellFactory.showServiceAlerts = TRUE;

		_serviceAlerts = [[OBAServiceAlertsModel alloc] init];
						
		CGRect r = CGRectMake(0, 0, 160, 33);
		_progressView = [[OBAProgressIndicatorView alloc] initWithFrame:r];
		[self.navigationItem setTitleView:_progressView];
		
		UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshButton:)];
		[self.navigationItem setRightBarButtonItem:refreshItem];
		[refreshItem release];
		
		_allArrivals = [[NSMutableArray alloc] init];
		_filteredArrivals = [[NSMutableArray alloc] init];
		_showFilteredArrivals = YES;
		
		self.navigationItem.title = @"Stop";
		
		[self customSetup];
	}
	return self;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stopId:(NSString*)stopId {
	if( self = [self initWithApplicationContext:appContext] ) {
		_stopId = [stopId retain];
	}
	return self;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stopIds:(NSArray*)stopIds {
	return [self initWithApplicationContext:appContext stopId:[stopIds objectAtIndex:0]];
}

- (void) dealloc {
	
	[self clearPendingRequest];
	
	[_stopId release];	
	[_result release];
	
	[_allArrivals release];
	[_filteredArrivals release];
	
	[_arrivalCellFactory release];
	[_progressView release];
	[_serviceAlerts release];
	
    [super dealloc];
}

- (OBAStopSectionType) sectionTypeForSection:(NSUInteger)section {
	
	OBAStopV2 * stop = _result.stop;
	
	if( stop ) {
		
		int offset = 0;
		
		if( _showTitle ) {
			if( section == offset )
				return OBAStopSectionTypeName;
			offset++;
		}
		
		if( _showServiceAlerts && _serviceAlerts.unreadCount > 0) {
			
			if( section == offset )
				return OBAStopSectionTypeServiceAlerts;
			offset++;
		}
		
		if( section == offset ) {
			return OBAStopSectionTypeArrivals;
		}
		offset++;
		
		if( [_filteredArrivals count] != [_allArrivals count] ) {
			if( section == offset )
				return OBAStopSectionTypeFilter;
			offset++;
		}
		
		if( _showActions ) {
			if( section == offset)
				return OBAStopSectionTypeActions;
			offset++;
		}
	}
	
	return OBAStopSectionTypeNone;
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	NSDictionary * params = [NSDictionary dictionaryWithObject:_stopId forKey:@"stopId"];
	return [OBANavigationTarget target:OBANavigationTargetTypeStop parameters:params];
}


- (void) setNavigationTarget:(OBANavigationTarget*)navigationTarget {
	_stopId = [NSObject releaseOld:_stopId retainNew:[navigationTarget parameterForKey:@"stopId"]];
	[self refresh];
}

#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];

	if ([[UIDevice currentDevice] isMultitaskingSupportedSafe])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground)  name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	}
	
	[self refresh];
}

- (void)viewWillDisappear:(BOOL)animated {
 
	[self clearPendingRequest];
	
	if ([[UIDevice currentDevice] isMultitaskingSupportedSafe])
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	}

}

- (void)didEnterBackground {
	
}


- (void)willEnterForeground {
	// will repaint the UITableView to update new time offsets and such when returning from the background.
	// this makes it so old data, represented with current times, from before the task switch will display
	// briefly before we fetch new data.
	[self reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	NSString * message = [NSString stringWithFormat:@"Updated: %@", [OBACommon getTimeAsString]];
	[_progressView setMessage:message inProgress:FALSE progress:0];
	[self didRefreshEnd];
	_result = [NSObject releaseOld:_result retainNew:obj];
	
	// Note the event
	[_appContext.activityListeners viewedArrivalsAndDeparturesForStop:_result.stop];

	[self reloadData];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
	if( code == 404 )
		[_progressView setMessage:@"Stop not found" inProgress:FALSE progress:0];
	else
		[_progressView setMessage:@"Unknown error" inProgress:FALSE progress:0];
	[self didRefreshEnd];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
	OBALogWarningWithError(error, @"Error... yay!");
	[_progressView setMessage:@"Error connecting" inProgress:FALSE progress:0];
	[self didRefreshEnd];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
	[_progressView setInProgress:TRUE progress:progress];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	OBAStopV2 * stop = _result.stop;
	
	if( stop ) {
		int count = 3;
		if( [_filteredArrivals count] != [_allArrivals count] )
			count++;
		if( _showServiceAlerts && _serviceAlerts.unreadCount > 0 )
			count++;
		return count;
	}
	
	return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	OBAStopSectionType sectionType = [self sectionTypeForSection:section];
	
	
	switch( sectionType ) {
		case OBAStopSectionTypeName:
			return 1;
		case OBAStopSectionTypeServiceAlerts:
			return 1;
		case OBAStopSectionTypeArrivals: {
			int c = 0;
			if( _showFilteredArrivals )
				c = [_filteredArrivals count];
			else
				c = [_allArrivals count];
			
			if( c == 0 )
				c = 1;
			
			return c;			
		}
		case OBAStopSectionTypeFilter:
			return 1;
		case OBAStopSectionTypeActions:
			return 5;
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	OBAStopSectionType sectionType = [self sectionTypeForSection:indexPath.section];

	switch (sectionType) {
		case OBAStopSectionTypeName:
			return [self tableView:tableView stopCellForRowAtIndexPath:indexPath];
		case OBAStopSectionTypeServiceAlerts:
			return [self tableView:tableView serviceAlertCellForRowAtIndexPath:indexPath];
		case OBAStopSectionTypeArrivals:
			return [self tableView:tableView predictedArrivalCellForRowAtIndexPath:indexPath];
		case OBAStopSectionTypeFilter:
			return [self tableView:tableView filterCellForRowAtIndexPath:indexPath];
		case OBAStopSectionTypeActions:
			return [self tableView:tableView actionCellForRowAtIndexPath:indexPath];
		default:
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBAStopSectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
			
		case OBAStopSectionTypeServiceAlerts:
			[self tableView:tableView didSelectServiceAlertRowAtIndexPath:indexPath];
			break;
			
		case OBAStopSectionTypeArrivals:
			[self tableView:tableView didSelectTripRowAtIndexPath:indexPath];
			break;
			
		case OBAStopSectionTypeFilter: {
			_showFilteredArrivals = !_showFilteredArrivals;
			
			// update arrivals section
			int arrivalsViewSection = [self sectionIndexForSectionType:OBAStopSectionTypeArrivals];

			UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
			[self determineFilterTypeCellText:cell filteringEnabled:_showFilteredArrivals];
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			
			if ([_filteredArrivals count] == 0)
			{
				// We're showing a "no arrivals in the next 30 minutes" message, so our insertion/deletion math below would be wrong.
				// Instead, just refresh the section with a fade.
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:arrivalsViewSection] withRowAnimation:UITableViewRowAnimationFade];
			}
			else if ([_allArrivals count] != [_filteredArrivals count])
			{
				// Display a nice animation of the cells when changing our filter settings
				NSMutableArray * modificationArray = [NSMutableArray arrayWithCapacity:[_allArrivals count] - [_filteredArrivals count]];
				
				int rowIterator = 0;
				for(OBAArrivalAndDepartureV2 * pa in _allArrivals)
				{
					bool isFilteredArrival = ([_filteredArrivals containsObject:pa] == NO);
					
					if (isFilteredArrival == YES)
						[modificationArray addObject:[NSIndexPath indexPathForRow:rowIterator inSection:arrivalsViewSection]];
					
					rowIterator++;
				}
				
				if (_showFilteredArrivals)
					[self.tableView deleteRowsAtIndexPaths:modificationArray withRowAnimation:UITableViewRowAnimationFade];
				else
					[self.tableView insertRowsAtIndexPaths:modificationArray withRowAnimation:UITableViewRowAnimationFade];
			}
			
			break;
		}
		
		case OBAStopSectionTypeActions:
			[self tableView:tableView didSelectActionRowAtIndexPath:indexPath];
			break;

		default:
			break;
	}
}

@end


@implementation OBAGenericStopViewController (Private)

- (void) customSetup {
	
}

- (void) refresh {
	[_progressView setMessage:@"Updating..." inProgress:TRUE progress:0];
	[self didRefreshBegin];
	
	OBAModelService * service = _appContext.modelService;
	
	[self clearPendingRequest];
	_request = [[service requestStopWithArrivalsAndDeparturesForId:_stopId withMinutesBefore:_minutesBefore withMinutesAfter:_minutesAfter withDelegate:self withContext:nil] retain];
	_timer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh) userInfo:nil repeats:TRUE] retain];
}
	 
- (void) clearPendingRequest {
	
	[_timer invalidate];
	[_timer release];
	_timer = nil;
	
	[_request cancel];
	[_request release];
	_request = nil;
}

- (void) didRefreshBegin {    
    
	// disable refresh button
    UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:nil action:@selector(onRefreshButton:)];
    [refreshItem setEnabled:NO];
	
    [self.navigationItem setRightBarButtonItem:refreshItem];
    [refreshItem release];
}

- (void) didRefreshEnd {
    
    // activate refresh button
    UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshButton:)];
	
    [self.navigationItem setRightBarButtonItem:refreshItem];
    [refreshItem release];
}

- (NSUInteger) sectionIndexForSectionType:(OBAStopSectionType)section {

	OBAStopV2 * stop = _result.stop;
	
	if( stop ) {
		
		int offset = 0;
		
		if( _showTitle ) {
			if( section == OBAStopSectionTypeName )
				return offset;
			offset++;
		}
		
		if( _showServiceAlerts && _serviceAlerts.unreadCount > 0) {
			if( section == OBAStopSectionTypeServiceAlerts )
				return offset;
			offset++;
		}
		
		if( section == OBAStopSectionTypeArrivals )
			return offset;
		offset++;
		
		if( [_filteredArrivals count] != [_allArrivals count] ) {
			if( section == OBAStopSectionTypeFilter )
				return offset;
			offset++;
		}
		
		if( _showActions ) {
			if( section == OBAStopSectionTypeActions)
				return offset;
			offset++;
		}
	}
	
	return 0;
	
}

- (UITableViewCell*) tableView:(UITableView*)tableView stopCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	OBAStopV2 * stop = _result.stop;

	if( stop ) {
		OBAStopTableViewCell * cell = [OBAStopTableViewCell getOrCreateCellForTableView:tableView];	
		[cell setStop:stop];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (UITableViewCell*) tableView:(UITableView*)tableView serviceAlertCellForRowAtIndexPath:(NSIndexPath *)indexPath {	
	return [OBAPresentation tableViewCellForUnreadServiceAlerts:_serviceAlerts tableView:tableView];
}

- (UITableViewCell*)tableView:(UITableView*)tableView predictedArrivalCellForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSArray * arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;
	
	if( [arrivals count] == 0 ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"No arrivals in the next 30 minutes";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
		return cell;
	}
	else {

		OBAArrivalAndDepartureV2 * pa = [arrivals objectAtIndex:indexPath.row];
		OBAArrivalEntryTableViewCell * cell = [_arrivalCellFactory createCellForArrivalAndDeparture:pa];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
}


- (void)determineFilterTypeCellText:(UITableViewCell*)filterTypeCell filteringEnabled:(bool)filteringEnabled {
	if( filteringEnabled )
		filterTypeCell.textLabel.text = @"Show all arrivals";
	else
		filterTypeCell.textLabel.text = @"Show filtered arrivals";	
}

- (UITableViewCell*) tableView:(UITableView*)tableView filterCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	
	[self determineFilterTypeCellText:cell filteringEnabled:_showFilteredArrivals];
	
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if( indexPath.row == 2 )
		return [OBAPresentation tableViewCellForServiceAlerts:_serviceAlerts tableView:tableView];
		
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	switch(indexPath.row) {
		case 0:
			cell.textLabel.text = @"Add to Bookmarks";
			break;
		case 1:
			cell.textLabel.text = @"Filter & Sort Routes";
			break;
		case 2:
			cell.textLabel.text = @"Service Alerts";
			break;
		case 3:
			cell.textLabel.text = @"See Nearby Stops";
			break;
		case 4:
			cell.textLabel.text = @"Report a Problem";
			break;			
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray * situations = _result.situations;
	[OBAPresentation showSituations:situations withAppContext:_appContext navigationController:self.navigationController args:nil];
}

- (void)tableView:(UITableView *)tableView didSelectTripRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray * arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;
	if ( 0 <= indexPath.row && indexPath.row < [arrivals count] ) {
		OBAArrivalAndDepartureV2 * arrivalAndDeparture = [arrivals objectAtIndex:indexPath.row];
		OBAArrivalAndDepartureViewController * vc = [[OBAArrivalAndDepartureViewController alloc] initWithApplicationContext:_appContext arrivalAndDeparture:arrivalAndDeparture];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
}

- (void)tableView:(UITableView *)tableView didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath {
	switch(indexPath.row) {
		case 0: {
			OBABookmarkV2 * bookmark = [_appContext.modelDao createTransientBookmark:_result.stop];
			
			OBAEditStopBookmarkViewController * vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationContext:_appContext bookmark:bookmark editType:OBABookmarkEditNew];
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
			
			break;
		}
			
		case 1: {
			OBAEditStopPreferencesViewController * vc = [[OBAEditStopPreferencesViewController alloc] initWithApplicationContext:_appContext stop:_result.stop];
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
			
			break;
		}
			
		case 2: {
			NSArray * situations = _result.situations;
			[OBAPresentation showSituations:situations withAppContext:_appContext navigationController:self.navigationController args:nil];
			break;
		}
			
		case 3: {
			OBAStopV2 * stop = _result.stop;
			MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:stop.coordinate latRadius:kNearbyStopRadius lonRadius:kNearbyStopRadius];
			OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchLocationRegion:region];
			[_appContext navigateToTarget:target];
			break;
		}
			
		case 4: {
			OBAReportProblemViewController * vc = [[OBAReportProblemViewController alloc] initWithApplicationContext:_appContext stop:_result.stop];
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
			
			break;
		}
	}
	
}

- (IBAction)onRefreshButton:(id)sender {
	[self refresh];
}

NSComparisonResult predictedArrivalSortByDepartureTime(id pa1, id pa2, void * context) {
	return ((OBAArrivalAndDepartureV2*)pa1).bestDepartureTime - ((OBAArrivalAndDepartureV2*)pa2).bestDepartureTime;
}

NSComparisonResult predictedArrivalSortByRoute(id o1, id o2, void * context) {
	OBAArrivalAndDepartureV2* pa1 = o1;
	OBAArrivalAndDepartureV2* pa2 = o2;
	
	OBARouteV2 * r1 = pa1.route;
	OBARouteV2 * r2 = pa2.route;
	NSComparisonResult r = [r1 compareUsingName:r2];
	
	if( r == 0)
		r = predictedArrivalSortByDepartureTime(pa1,pa2,context);
	
	return r;
}

- (void) reloadData {
		
	OBAModelDAO * modelDao = _appContext.modelDao;
	OBAStopV2 * stop = _result.stop;
	
	NSArray * predictedArrivals = _result.arrivalsAndDepartures;
	
	[_allArrivals removeAllObjects];
	[_filteredArrivals removeAllObjects];
	
	if(stop && predictedArrivals) {
		
		OBAStopPreferencesV2 * prefs = [modelDao stopPreferencesForStopWithId:stop.stopId];
		
		for( OBAArrivalAndDepartureV2 * pa in predictedArrivals) {
			[_allArrivals addObject:pa];
			if( [prefs isRouteIdEnabled:pa.routeId] )
				[_filteredArrivals addObject:pa];
		}
		
		switch (prefs.sortTripsByType) {
			case OBASortTripsByDepartureTimeV2:
				[_allArrivals sortUsingFunction:predictedArrivalSortByDepartureTime context:nil];
				[_filteredArrivals sortUsingFunction:predictedArrivalSortByDepartureTime context:nil];
				break;
			case OBASortTripsByRouteNameV2:
				[_allArrivals sortUsingFunction:predictedArrivalSortByRoute context:nil];
				[_filteredArrivals sortUsingFunction:predictedArrivalSortByRoute context:nil];
				break;
		}
	}
	
	_serviceAlerts = [[modelDao getServiceAlertsModelForSituations:_result.situations] retain];
	
	[self.tableView reloadData];
}

@end



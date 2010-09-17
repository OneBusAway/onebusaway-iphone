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

#import "OBAStopViewController.h"
#import "OBALogger.h"
#import "OBAArrivalAndDeparture.h"

#import "OBAUIKit.h"

#import "OBAUITableViewCell.h"
#import "OBAStopTableViewCell.h"
#import "OBAArrivalEntryTableViewCell.h"

#import "OBAProgressIndicatorView.h"

#import "OBAStopPreferences.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBAEditStopPreferencesViewController.h"

#import "OBASearchController.h"
#import "OBASphericalGeometryLibrary.h"

#import "UIDeviceExtensions.h"


static const double kNearbyStopRadius = 200;

typedef enum {
	OBASectionNone, OBASectionStop, OBASectionArrivals, OBASectionFilter, OBASectionOptions
} OBASectionType;
	
@interface OBAStopViewController (Internal)

- (void) refresh;
- (void) didRefreshBegin;
- (void) didRefreshEnd;
- (void) stopTimer;

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell*) tableView:(UITableView*)tableView stopCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView predictedArrivalCellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)determineFilterTypeCellText:(UITableViewCell*)filterTypeCell filteringEnabled:(bool)filteringEnabled;
- (UITableViewCell*) tableView:(UITableView*)tableView filterCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath;

- (void) reloadData;

@end


@implementation OBAStopViewController

@synthesize stopId = _stopId;
@synthesize request = _request;
@synthesize result = _result;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {

		_appContext = [appContext retain];
		//_source = [[OBAStopAndPredictedArrivalsSearch alloc] initWithContext:appContext];
		
		_minutesAfter = 35;
		
		_timeFormatter = [[NSDateFormatter alloc] init];
		[_timeFormatter setDateStyle:NSDateFormatterNoStyle];
		[_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
						
		_progressView = [[OBAProgressIndicatorView viewFromNib] retain];
		[self.navigationItem setTitleView:_progressView];
		
		UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshButton:)];
		[self.navigationItem setRightBarButtonItem:refreshItem];
		[refreshItem release];
		
		_allArrivals = [[NSMutableArray alloc] init];
		_filteredArrivals = [[NSMutableArray alloc] init];
		_showFilteredArrivals = YES;
		
		self.navigationItem.title = @"Stop";
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
	
	[self stopTimer];
	
	[_stopId release];	
	[_request cancel];
	[_request release];
	[_result release];
	
	[_allArrivals release];
	[_filteredArrivals release];
	
	[_timeFormatter release];
	[_progressView release];
	
    [super dealloc];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	NSDictionary * params = [NSDictionary dictionaryWithObject:_stopId forKey:@"stopId"];
	return [OBANavigationTarget target:OBANavigationTargetTypeStop parameters:params];
}


- (void) setNavigationTarget:(OBANavigationTarget*)navigationTarget {
	self.stopId = [navigationTarget parameterForKey:@"stopId"];
	[self refresh];
}

#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated {
    OBALogInfo(@"OBAStopViewController viewWillAppear: %@", self);
    
    [super viewWillAppear:animated];

	if ([[UIDevice currentDevice] isMultitaskingSupportedSafe])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground)  name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	}
	
	[self refresh];
}

- (void)viewWillDisappear:(BOOL)animated {
    OBALogInfo(@"OBAStopViewController viewWillDisspear: %@", self);
 
	[super viewWillDisappear:animated];
	
	[self stopTimer];
	
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
	self.result = obj;
	
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
		if( [_filteredArrivals count] != [_allArrivals count] ) {
			return 4;
		}
		return 3;
	}
	
	return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionStop:
			return 1;
		case OBASectionArrivals: {
			int c = 0;
			if( _showFilteredArrivals )
				c = [_filteredArrivals count];
			else
				c = [_allArrivals count];
			
			if( c == 0 )
				c = 1;				
			return c;			
		}
		case OBASectionFilter:
			return 1;
		case OBASectionOptions:
			return 3;
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

	switch (sectionType) {
		case OBASectionStop:
			return [self tableView:tableView stopCellForRowAtIndexPath:indexPath];
		case OBASectionArrivals:
			return [self tableView:tableView predictedArrivalCellForRowAtIndexPath:indexPath];
		case OBASectionFilter:
			return [self tableView:tableView filterCellForRowAtIndexPath:indexPath];
		case OBASectionOptions:
			return [self tableView:tableView actionCellForRowAtIndexPath:indexPath];
		default:
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionFilter: {
			_showFilteredArrivals = !_showFilteredArrivals;
			
			// update arrivals section
			static int arrivalsViewSection = 1;
			if ([self sectionTypeForSection:arrivalsViewSection] == OBASectionArrivals)
			{
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
					for(OBAArrivalAndDeparture * pa in _allArrivals)
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
			}
			
			break;
		}
		
		case OBASectionOptions:
			[self tableView:tableView didSelectActionRowAtIndexPath:indexPath];
			break;

		default:
			break;
	}
}

@end


@implementation OBAStopViewController (Internal)

- (void) refresh {
	[_progressView setMessage:@"Updating..." inProgress:TRUE progress:0];
	[self didRefreshBegin];
	
	OBAModelService * service = _appContext.modelService;
	self.request = [service requestStopWithArrivalsAndDeparturesForId:_stopId withMinutesAfter:_minutesAfter withDelegate:self withContext:nil];
	
	if( ! _timer ) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh) userInfo:nil repeats:TRUE];
		[_timer retain];
	}	
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

- (void) stopTimer {
	if( _timer ) {
		[_timer invalidate];
		[_timer release];
		_timer = nil;
	}	
}

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	OBAStopV2 * stop = _result.stop;
		
	if( stop ) {
		
		if( section == 0 )
			return OBASectionStop;
		if( section == 1 )
			return OBASectionArrivals;
		if( section == 2) {
			if( [_filteredArrivals count] != [_allArrivals count] )
				return OBASectionFilter;
			else
				return OBASectionOptions;
		}
		else if (section == 3 ) {
			return OBASectionOptions;
		}
	}
	
	return OBASectionNone;
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
		OBAArrivalEntryTableViewCell * cell = [OBAArrivalEntryTableViewCell getOrCreateCellForTableView:tableView];
		
		OBAArrivalAndDeparture * pa = [arrivals objectAtIndex:indexPath.row];
		cell.destinationLabel.text = pa.tripHeadsign;
		cell.routeLabel.text = pa.routeShortName;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
		NSDate * time = [NSDate dateWithTimeIntervalSince1970:(pa.bestDepartureTime / 1000)];		
		
		NSTimeInterval interval = [time timeIntervalSinceNow];
		int minutes = interval / 60;
		
		NSString * status;
		
		if(abs(minutes) <=1)
			cell.minutesLabel.text = @"NOW";
		else
			cell.minutesLabel.text = [NSString stringWithFormat:@"%d",minutes];
		
		if( pa.predictedDepartureTime > 0 ) {
			double diff = (pa.predictedDepartureTime - pa.scheduledDepartureTime) / ( 1000.0 * 60.0);
			int minDiff = (int) abs(diff);
			if( diff < -1.5) {
				cell.minutesLabel.textColor = [UIColor redColor];
				if( minutes < 0 )
					status = [NSString stringWithFormat:@"departed %d min early",minDiff];
				else
					status = [NSString stringWithFormat:@"%d min early",minDiff];
			}
			else if( diff < 1.5 ) {
				cell.minutesLabel.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
				if( minutes < 0 )
					status = @"departed on time";
				else
					status = @"on time";
			}
			else {
				cell.minutesLabel.textColor = [UIColor blueColor];
				if( minutes < 0 )
					status = [NSString stringWithFormat:@"departed %d min late",minDiff];
				else
					status = [NSString stringWithFormat:@"%d min delay",minDiff];
			}
		}
		else {
			cell.minutesLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];;
			if( minutes < 0 )
				status = @"scheduled departure";
			else
				status = @"scheduled arrival";
			
		}
		
		cell.timeLabel.text = [NSString stringWithFormat:@"%@ - %@",[_timeFormatter stringFromDate:time],status];
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
			cell.textLabel.text = @"See Nearby Stops";
			break;
	}
	
	return cell;
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
			OBAStopV2 * stop = _result.stop;
			MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:stop.coordinate latRadius:kNearbyStopRadius lonRadius:kNearbyStopRadius];
			OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchLocationRegion:region];
			[_appContext navigateToTarget:target];
			break;
		}
	}
	
}

- (IBAction)onRefreshButton:(id)sender {
	[self refresh];
}

NSComparisonResult predictedArrivalSortByDepartureTime(id pa1, id pa2, void * context) {
	return ((OBAArrivalAndDeparture*)pa1).bestDepartureTime - ((OBAArrivalAndDeparture*)pa2).bestDepartureTime;
}

NSComparisonResult predictedArrivalSortByRoute(id o1, id o2, void * context) {
	OBAArrivalAndDeparture* pa1 = o1;
	OBAArrivalAndDeparture* pa2 = o2;
	
	NSComparisonResult r = [pa1.route compareUsingName:pa2.route];
	
	if( r == 0)
		r = predictedArrivalSortByDepartureTime(pa1,pa2,context);
	
	return r;
}

- (void) reloadData {
	@synchronized(self) {
		OBAStopV2 * stop = _result.stop;
		
		NSArray * predictedArrivals = _result.arrivalsAndDepartures;
		
		[_allArrivals removeAllObjects];
		[_filteredArrivals removeAllObjects];
		
		if(stop && predictedArrivals) {
			OBAModelDAO * modelDao = _appContext.modelDao;	
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

		[self.tableView reloadData];
	}
}


@end



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

#import "UIDeviceExtensions.h"


typedef enum {
	OBASectionNone, OBASectionStop, OBASectionArrivals, OBASectionFilter, OBASectionOptions
} OBASectionType;
	
@interface OBAStopViewController (Internal)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell*) tableView:(UITableView*)tableView stopCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView predictedArrivalCellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)determineFilterTypeCellText:(UITableViewCell*)filterTypeCell filteringEnabled:(bool)filteringEnabled;
- (UITableViewCell*) tableView:(UITableView*)tableView filterCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void) reloadData;

@end


@implementation OBAStopViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {

		_appContext = [appContext retain];
		_source = [[OBAStopAndPredictedArrivalsSearch alloc] initWithContext:appContext];
		
		_timeFormatter = [[NSDateFormatter alloc] init];
		[_timeFormatter setDateStyle:NSDateFormatterNoStyle];
		[_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
						
		OBAProgressIndicatorView * view = [OBAProgressIndicatorView viewFromNibWithSource:_source.progress];
		[self.navigationItem setTitleView:view];
		
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

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stop:(OBAStop*)stop {
	self = [self initWithApplicationContext:appContext];
	[_source searchForStopId:stop.stopId];
	return self;
}

- (void)dealloc {
	[_source cancelOpenConnections];
	[_source release];
	
	[_allArrivals release];
	[_filteredArrivals release];
	
	[_timeFormatter release];
	
    [super dealloc];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [_source getSearchTarget];
}


- (void) setNavigationTarget:(OBANavigationTarget*)navigationTarget {
	[_source setSearchTarget:navigationTarget];
}


- (void)viewWillAppear:(BOOL)animated {
    OBALogInfo(@"OBAStopViewController viewWillAppear: %@", self);
    
    [super viewWillAppear:animated];

	[_source addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];

	if ([[UIDevice currentDevice] isMultitaskingSupportedSafe])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground)  name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRefreshBegin:) name:OBARefreshBeganNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRefreshEnd:)   name:OBARefreshEndedNotification object:nil];
	
	[self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    OBALogInfo(@"OBAStopViewController viewWillDisspear: %@", self);
 
	[super viewWillDisappear:animated];

	[_source removeObserver:self forKeyPath:@"error"];
	
	if ([[UIDevice currentDevice] isMultitaskingSupportedSafe])
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self name:OBARefreshBeganNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OBARefreshEndedNotification object:nil];
}

- (void)didEnterBackground {
	
}


- (void)willEnterForeground {
	// will repaint the UITableView to update new time offsets and such when returning from the background.
	// this makes it so old data, represented with current times, from before the task switch will display
	// briefly before we fetch new data.
	[self reloadData];
}

- (void)didRefreshBegin:(NSNotification*)notification {
    // only refresh for this stop's view
    if ([notification object] != _source)
        return;
    
    // disable refresh button
    UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:nil action:@selector(onRefreshButton:)];
    [refreshItem setEnabled:NO];

    [self.navigationItem setRightBarButtonItem:refreshItem];
    [refreshItem release];
}

- (void)didRefreshEnd:(NSNotification*)notification {
    // only refresh for this stop's view
    if ([notification object] != _source)
        return;
    
    // activate refresh button
    UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshButton:)];
  
    [self.navigationItem setRightBarButtonItem:refreshItem];
    [refreshItem release];
    
    // refresh the view with new data
    [self reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	OBAStop * stop = _source.stop;
	
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
			return 2;
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
		case OBASectionOptions: {            
            switch(indexPath.row) {
                case 0: {
                    OBABookmark * bookmark = [_appContext.modelDao createTransientBookmark:_source.stop];
                    
                    OBAEditStopBookmarkViewController * vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationContext:_appContext bookmark:bookmark editType:OBABookmarkEditNew];
                    [self.navigationController pushViewController:vc animated:YES];
                    [vc release];
                    
                    break;
                }

                case 1: {
                    OBAEditStopPreferencesViewController * vc = [[OBAEditStopPreferencesViewController alloc] initWithApplicationContext:_appContext stop:_source.stop];
                    [self.navigationController pushViewController:vc animated:YES];
                    [vc release];
                    
                    break;
                }
            }

			break;
		}
		default:
			break;
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	if ([keyPath isEqual:@"error"]) {
		if( _source.error )
			OBALogWarningWithError(_source.error, @"Error... yay!");
	}
}


@end

@implementation OBAStopViewController (Internal)


- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	OBAStop * stop = _source.stop;
		
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
	OBAStop * stop = _source.stop;
	
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
	
    if (indexPath.row == 0)
		cell.textLabel.text = @"Add to Bookmarks";
	else if (indexPath.row == 1)
		cell.textLabel.text = @"Filter & Sort Routes";

	return cell;
}

- (IBAction)onRefreshButton:(id)sender {
	[_source refresh];
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
		OBAStop * stop = _source.stop;
		
		NSArray * predictedArrivals = _source.predictedArrivals;
		
		[_allArrivals removeAllObjects];
		[_filteredArrivals removeAllObjects];
		
		if(stop && predictedArrivals) {
			OBAStopPreferences * prefs = stop.preferences;
			
			for( OBAArrivalAndDeparture * pa in predictedArrivals) {
				[_allArrivals addObject:pa];
				
				if( ! [prefs.routesToExclude containsObject:pa.route] )
					[_filteredArrivals addObject:pa];
			}

			switch ([prefs.sortTripsByType intValue]) {
				case OBASortTripsByDepartureTime:
					[_allArrivals sortUsingFunction:predictedArrivalSortByDepartureTime context:nil];
					[_filteredArrivals sortUsingFunction:predictedArrivalSortByDepartureTime context:nil];
					break;

				case OBASortTripsByRouteName:
					[_allArrivals sortUsingFunction:predictedArrivalSortByRoute context:nil];
					[_filteredArrivals sortUsingFunction:predictedArrivalSortByRoute context:nil];
					break;
			}
		}

		[self.tableView reloadData];
	}
}


@end



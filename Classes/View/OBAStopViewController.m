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
#import "OBAEditStopBookmarkViewController.h"
#import "OBAEditStopPreferencesViewController.h"


@implementation OBAStopViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {

	if (self = [super initWithStyle:UITableViewStyleGrouped]) {

		_appContext = [appContext retain];
		_source = [[OBAStopAndPredictedArrivalsSearch alloc] initWithContext:appContext];
		
		_timeFormatter = [[NSDateFormatter alloc] init];
		[_timeFormatter setDateStyle:NSDateFormatterNoStyle];
		[_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
						
		NSMutableArray * items = [[NSMutableArray alloc] init];
		
		UIBarButtonItem * actionItem = [[UIBarButtonItem alloc] initWithTitle:@"More" style:UIBarButtonItemStyleBordered target:self action:@selector(onActionButton:)];
		actionItem.style = UIBarButtonItemStyleBordered;
		[items addObject:actionItem];
		[actionItem release];
		

		UIBarButtonItem * spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:@selector(onAddBookmarkButton:)];
		[items addObject:spaceItem];
		[spaceItem release];
		
		OBAProgressIndicatorView * view = [OBAProgressIndicatorView viewFromNibWithSource:_source.progress];
		UIBarButtonItem * progressItem = [[UIBarButtonItem alloc] initWithCustomView:view];
		[items addObject:progressItem];
		[progressItem release];

		spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:@selector(onAddBookmarkButton:)];
		[items addObject:spaceItem];
		[spaceItem release];
		
		UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshButton:)];
		[items addObject:refreshItem];
		[refreshItem release];
		
		self.toolbarItems = items;
		
		[items release];
		
		_allArrivals = [[NSMutableArray alloc] init];
		_filteredArrivals = [[NSMutableArray alloc] init];
		_showFilteredArrivals = YES;
		
		self.navigationItem.title = @"Stop";
		
		self.hidesBottomBarWhenPushed = TRUE;
	}
	return self;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stop:(OBAStop*)stop {
	self = [self initWithApplicationContext:appContext];
	[_source searchForStopId:stop.stopId];
	return self;
}

- (void)dealloc {

	[_context release];
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

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
		
	[_source addObserver:self forKeyPath:@"stop" options:NSKeyValueObservingOptionNew context:nil];
	[_source addObserver:self forKeyPath:@"predictedArrivals" options:NSKeyValueObservingOptionNew context:nil];
	[_source addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];	

	[self.navigationController setToolbarHidden:FALSE];

	[self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	self.navigationController.toolbarHidden = TRUE;
	
	[_source removeObserver:self forKeyPath:@"stop"];
	[_source removeObserver:self forKeyPath:@"predictedArrivals"];
	[_source removeObserver:self forKeyPath:@"error"];	
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	OBAStop * stop = _source.stop;
	NSArray * predictedArrivals = _source.predictedArrivals;
	
	if( stop ) {
		if( predictedArrivals ) {
			if( [_filteredArrivals count] != [predictedArrivals count] ) {
				return 3;
			}
			return 2;
		}
		return 1;
	}
	
	return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	OBAStop * stop = _source.stop;
	NSArray * predictedArrivals = _source.predictedArrivals;
	
	if( stop ) {

		if( section == 0 ) {
			return 1;
		}
		else if( section == 1 ) {
			
			int c = 0;
			if( predictedArrivals ) {
				if( _showFilteredArrivals )
					c = [_filteredArrivals count];
				else
					c = [predictedArrivals count];
				
				if( c == 0 )
					c = 1;				
			}
			return c;
		}
		else if( section == 2) {
			return 1;
		}
	}
	
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	if( indexPath.section == 0 ) {
		return [self tableView:tableView stopCellForRowAtIndexPath:indexPath];
	}
	else if( indexPath.section == 1) {
		return [self tableView:tableView predictedArrivalCellForRowAtIndexPath:indexPath];
	}
	else if( indexPath.section == 2) {
		return [self tableView:tableView filterCellForRowAtIndexPath:indexPath];
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (UITableViewCell*) tableView:(UITableView*)tableView stopCellForRowAtIndexPath:(NSIndexPath *)indexPath {

	OBAStop * stop = _source.stop;
	
	if( stop ) {
		OBAStopTableViewCell * cell = [OBAStopTableViewCell getOrCreateCellForTableView:tableView];	
		[cell setStop:stop];
		return cell;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (UITableViewCell*)tableView:(UITableView*)tableView predictedArrivalCellForRowAtIndexPath:(NSIndexPath*)indexPath {
	
	NSArray * predictedArrivals = _source.predictedArrivals;
	
	if( ! predictedArrivals )
		return [UITableViewCell getOrCreateCellForTableView:tableView];
	
	NSArray * arrivals = _showFilteredArrivals ? _filteredArrivals : predictedArrivals;
	
	if( [arrivals count] == 0 ) {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		cell.textLabel.text = @"No arrivals in the next 30 minutes";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		return cell;
	}
	else {
		OBAArrivalEntryTableViewCell * cell = [OBAArrivalEntryTableViewCell getOrCreateCellForTableView:tableView];
		
		OBAArrivalAndDeparture * pa = [arrivals objectAtIndex:indexPath.row];
		cell.destinationLabel.text = pa.tripHeadsign;
		cell.routeLabel.text = pa.routeShortName;
		
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
				status = [NSString stringWithFormat:@"%d min early",minDiff];
			}
			else if( diff < 1.5 ) {
				cell.minutesLabel.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
				status = @"on time";
			}
			else {
				cell.minutesLabel.textColor = [UIColor blueColor];
				status = [NSString stringWithFormat:@"%d min delay",minDiff];
			}
		}
		else {
			cell.minutesLabel.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];;
			if( minutes < 0 )
				status = @"scheduled departure";
			else
				status = @"scheduled arrival";
			
		}
		
		cell.timeLabel.text = [NSString stringWithFormat:@"%@ - %@",[_timeFormatter stringFromDate:time],status];
		return cell;
	}
}

- (UITableViewCell*) tableView:(UITableView*)tableView filterCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	
	if( _showFilteredArrivals )
		cell.textLabel.text = @"Show all arrivals";
	else
		cell.textLabel.text = @"Show filtered arrivals";
	
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if( indexPath.section == 2) {
		_showFilteredArrivals = ! _showFilteredArrivals;
		[self.tableView reloadData];
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	if ([keyPath isEqual:@"error"]) {
		if( _source.error )
			OBALogWarningWithError(_source.error,@"Error... yay!");
	}
	else if([keyPath isEqual:@"stop"] || [keyPath isEqual:@"predictedArrivals"]) {
		[self reloadData];
	}
}

- (IBAction)onRefreshButton:(id)sender {
	[_source refresh];
}

- (IBAction) onActionButton:(id)sender {
	UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:@"Action" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
	[actionSheet addButtonWithTitle:@"Add Bookmark"];
	[actionSheet addButtonWithTitle:@"Filter"];
	[actionSheet addButtonWithTitle:@"Cancel"];
	actionSheet.cancelButtonIndex = 2;
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch(buttonIndex) {
		case 0: {
			OBAStop * stop = _source.stop;
			if( ! stop )
				return;
			OBABookmark * bookmark = [_appContext.modelDao createTransientBookmark:stop];
			OBAEditStopBookmarkViewController * vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationContext:_appContext bookmark:bookmark editType:OBABookmarkEditNew];
			[self.navigationController pushViewController:vc animated:YES];
			break;
		}
		case 1: {
			OBAStop * stop = _source.stop;
			if( ! stop )
				return;
			OBAEditStopPreferencesViewController * vc = [[OBAEditStopPreferencesViewController alloc] initWithApplicationContext:_appContext stop:stop];
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
			break;
		}
	}
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
	
		if( stop && predictedArrivals) {

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


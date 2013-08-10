//
//  OBARegionListViewController.m
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/15/13.
//
//

#import "OBARegionListViewController.h"
#import "OBARegionV2.h"

typedef enum {
	OBASectionTypeNone,
    OBASectionTypeLoading,
    OBASectionTypeTitle,
    OBASectionTypeNearbyRegions,
	OBASectionTypeAllRegions,
	OBASectionTypeNoRegions,
} OBASectionType;


@interface OBARegionListViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;
- (UITableViewCell*) regionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (void) didSelectRegionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end

@implementation OBARegionListViewController

- (id) initWithApplicationContext:(OBAApplicationDelegate*)appContext {
	if( self = [super initWithApplicationContext:appContext] ) {
		self.refreshable = NO;
		self.showUpdateTime = NO;
	}
	return self;
}

-(void) viewDidLoad {
	self.refreshable = NO;
	self.showUpdateTime = NO;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	self.navigationItem.title = NSLocalizedString(@"Select Region",@"self.navigationItem.title");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCompleteNetworkRequest) name:OBAApplicationDidCompleteNetworkRequestNotification object:nil];
	
    _locationTimedOut = NO;
	OBALocationManager * lm = _appContext.locationManager;
	[lm addDelegate:self];
	[lm startUpdatingLocation];
    
    _locationTimer = [NSTimer timerWithTimeInterval:60.0 target:self selector:@selector(timeOutLocation) userInfo:(self) repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_locationTimer forMode:NSRunLoopCommonModes];
    
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OBAApplicationDidCompleteNetworkRequestNotification object:nil];
    
	[_appContext.locationManager stopUpdatingLocation];
	[_appContext.locationManager removeDelegate:self];
}


- (void)dealloc {
	_regions = nil;
    _nearbyRegions = nil;
    _mostRecentLocation = nil;
    _locationTimer = nil;
}

- (BOOL) isLoading {
	return _regions == nil || (_mostRecentLocation == nil && !_locationTimedOut);
}

- (id<OBAModelServiceRequest>) handleRefresh {
	return [_appContext.modelService requestRegions:self withContext:nil];
}

- (void) handleData:(id)obj context:(id)context {
    OBAListWithRangeAndReferencesV2 * list = obj;
	_regions = [[NSMutableArray alloc] initWithArray:list.values];
    
    NSMutableArray *notSupportedRegions = [NSMutableArray array];
    for (id obj in _regions) {
        OBARegionV2 *region = (OBARegionV2 *)obj;
        if (!region.supportsObaRealtimeApis) {
            [notSupportedRegions addObject:region];
        }
    }
    [_regions removeObjectsInArray:notSupportedRegions];
    //NSLog(@"%f %f", _mostRecentLocation.coordinate.latitude, _mostRecentLocation.coordinate.longitude);
    //[self sortRegionsByLocation];
    [self sortRegionsByName];
}

- (void) sortRegionsByLocation {
    if (![self isLoading]) {
        _nearbyRegions = [NSMutableArray arrayWithArray:_regions];
        NSMutableArray *regionsToRemove = [NSMutableArray array];
        for (id obj in _nearbyRegions) {
            OBARegionV2 *region = (OBARegionV2 *) obj;
            CLLocationDistance distance = [region distanceFromLocation:_mostRecentLocation];
            if (distance > 160934) { // 100 miles
                [regionsToRemove addObject:obj];
            }
        }
        
        [_nearbyRegions removeObjectsInArray:regionsToRemove];
        
        [_nearbyRegions sortUsingComparator:^(id obj1, id obj2) {
            OBARegionV2 *region1 = (OBARegionV2*) obj1;
            OBARegionV2 *region2 = (OBARegionV2*) obj2;
            
            CLLocationDistance distance1 = [region1 distanceFromLocation:_mostRecentLocation];
            CLLocationDistance distance2 = [region2 distanceFromLocation:_mostRecentLocation];
            
            if (distance1 > distance2) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            else if (distance1 < distance2) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            else {
                return (NSComparisonResult)NSOrderedSame;
            }
        }];
        [self.tableView reloadData];
    }
}

- (void) sortRegionsByName {
    [_regions sortUsingComparator:^(id obj1, id obj2) {
        OBARegionV2 *region1 = (OBARegionV2*) obj1;
        OBARegionV2 *region2 = (OBARegionV2*) obj2;
        
        return [region1.regionName compare:region2.regionName];
    }];
}

- (void) timeOutLocation:(NSTimer*)theTimer {
    _locationTimedOut = TRUE;
    
    [self sortRegionsByLocation];
}

#pragma mark OBALocationManagerDelegate Methods

- (void) locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location {
    OBALocationManager * lm = _appContext.locationManager;
	CLLocation * newLocation = lm.currentLocation;
	_mostRecentLocation = [NSObject releaseOld:_mostRecentLocation retainNew:newLocation];
    [_locationTimer invalidate];
    [self sortRegionsByLocation];
}

- (void) locationManager:(OBALocationManager *)manager didFailWithError:(NSError*)error {
	if( [error domain] == kCLErrorDomain && [error code] == kCLErrorDenied ) {
		[self showLocationServicesAlert];
	}
    [_locationTimer invalidate];
    _locationTimedOut = TRUE;
    [self sortRegionsByLocation];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
    if (_regions == nil)
        return 1;
    else if ([_regions count] == 0)
        return 1;
	else if( _nearbyRegions == nil || [_nearbyRegions count] == 0 )
        return 2;
    else
        return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if( [self isLoading] )
		return [super tableView:tableView numberOfRowsInSection:section];
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionTypeAllRegions:
			return [_regions count];
        case OBASectionTypeNearbyRegions:
            return [_nearbyRegions count];
		default:
			return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    OBASectionType sectionType = [self sectionTypeForSection:section];
    
    switch (sectionType) {
        case OBASectionTypeLoading:
            return @"Loading available regions...";
        case OBASectionTypeTitle:
            return @"Select the region where you wish to use OneBusAway";
        case OBASectionTypeNearbyRegions:
            return @"Nearby Regions";
        case OBASectionTypeAllRegions:
            return @"Available Regions";
        case OBASectionTypeNoRegions:
            return @"No regions found";
        default:
            return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if( [self isLoading] )
		return [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeAllRegions:
			return [self regionsCellForRowAtIndexPath:indexPath tableView:tableView];
        case OBASectionTypeNearbyRegions:
            return [self regionsCellForRowAtIndexPath:indexPath tableView:tableView];
		default:
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if( [self isLoading] ) {
		[self tableView:tableView didSelectRowAtIndexPath:indexPath];
		return;
	}
	
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeAllRegions:
			[self didSelectRegionRowAtIndexPath:indexPath tableView:tableView];
			break;
        case OBASectionTypeNearbyRegions:
            [self didSelectRegionRowAtIndexPath:indexPath tableView:tableView];
            break;
		default:
			break;
	}
	
}

- (void) didCompleteNetworkRequest {
	_hideFutureNetworkErrors = NO;
}

- (void) showLocationServicesAlert {
	
	if (! [_appContext.modelDao hideFutureLocationWarnings]) {
		[_appContext.modelDao setHideFutureLocationWarnings:TRUE];
		
		UIAlertView * view = [[UIAlertView alloc] init];
		view.title = NSLocalizedString(@"Location Services Disabled",@"view.title");
		view.message = NSLocalizedString(@"Location Services are disabled for this app.  Some location-aware functionality will be missing.",@"view.message");
		[view addButtonWithTitle:NSLocalizedString(@"Dismiss",@"view addButtonWithTitle")];
		view.cancelButtonIndex = 0;
		[view show];
	}
}

@end

@implementation OBARegionListViewController (Private)


- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	
    if (_regions == nil) {
        if (section == 0)
            return OBASectionTypeLoading;
    }
	else if( [_regions count] == 0 ) {
		if( section == 0 )
			return OBASectionTypeNoRegions;
	}
	else {
		if( section == 0 )
            return OBASectionTypeTitle;
        else if (_nearbyRegions == nil || [_nearbyRegions count] == 0) {
            if (section == 1)
                return OBASectionTypeAllRegions;
        }
        else {
            if (section == 1)
                return OBASectionTypeNearbyRegions;
            else if (section == 2)
                return OBASectionTypeAllRegions;
        }
	}
	
	return OBASectionTypeNone;
}

- (UITableViewCell*) regionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    OBARegionV2 *region = nil;
    
    switch ([self sectionTypeForSection:indexPath.section]) {
        case OBASectionTypeNearbyRegions:
            region = [_nearbyRegions objectAtIndex:indexPath.row];
            break;
        case OBASectionTypeAllRegions:
            region = [_regions objectAtIndex:indexPath.row];
            break;
        default:
            return nil;
            break;
    }
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.textLabel.textColor = [UIColor blackColor];
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.textLabel.text = region.regionName;
	return cell;
}

- (void) didSelectRegionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	OBARegionV2 * region = nil;
    
    switch ([self sectionTypeForSection:indexPath.section]) {
        case OBASectionTypeNearbyRegions:
            region = [_nearbyRegions objectAtIndex:indexPath.row];
            break;
        case OBASectionTypeAllRegions:
            region = [_regions objectAtIndex:indexPath.row];
            break;
        default:
            return ;
            break;
    }
    
    [_appContext.modelDao setOBARegion:region];
    [_appContext regionSelected];
	//[[UIApplication sharedApplication] openURL: [NSURL URLWithString: agency.url]];
}


@end
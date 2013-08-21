//
//  OBARegionListViewController.m
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/15/13.
//
//

#import "OBARegionListViewController.h"
#import "OBARegionV2.h"
#import "OBACustomApiViewController.h"


typedef enum {
	OBASectionTypeNone,
    OBASectionTypeLoading,
    OBASectionTypeTitle,
    OBASectionTypeNearbyRegions,
	OBASectionTypeAllRegions,
	OBASectionTypeNoRegions,
    OBASectionTypeCustomAPI,
} OBASectionType;

@interface OBARegionListViewController ()

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;
- (UITableViewCell*) regionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (void) didSelectRegionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (UITableViewCell*) customAPICellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (void) didSelectCustomAPIRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
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
    self.progressLabel = NSLocalizedString(@"Regions", @"regions title");
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
    [_locationTimer invalidate];
}


- (void)dealloc {
	_regions = nil;
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
        if (!region.supportsObaRealtimeApis || !region.active) {
            [notSupportedRegions addObject:region];
        }
    }
    [_regions removeObjectsInArray:notSupportedRegions];
    //NSLog(@"%f %f", _mostRecentLocation.coordinate.latitude, _mostRecentLocation.coordinate.longitude);
    //[self sortRegionsByLocation];
    [self sortRegionsByName];
}

- (void) sortRegionsByLocation {
    if (![self isLoading] && _mostRecentLocation) {
        NSMutableArray *nearbyRegions = [NSMutableArray arrayWithArray:_regions];
        NSMutableArray *regionsToRemove = [NSMutableArray array];
        for (id obj in nearbyRegions) {
            OBARegionV2 *region = (OBARegionV2 *) obj;
            CLLocationDistance distance = [region distanceFromLocation:_mostRecentLocation];
            if (distance > 160934) { // 100 miles
                [regionsToRemove addObject:obj];
            }
        }
        
        [nearbyRegions removeObjectsInArray:regionsToRemove];
        
        [nearbyRegions sortUsingComparator:^(id obj1, id obj2) {
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
        if (nearbyRegions.count > 0) {
            self.nearbyRegion = [nearbyRegions objectAtIndex:0];
        } else {
            self.nearbyRegion = nil;
        }
    }
    [self.tableView reloadData];
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
	
    if([self isLoading])
        return 1;
    else if(_regions == nil)
        return 2;
    else if ([_regions count] == 0)
        return 2;
	else if( self.nearbyRegion == nil)
        return 3;
    else
        return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if( [self isLoading] )
		return [super tableView:tableView numberOfRowsInSection:section];
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionTypeAllRegions:
			return [_regions count];
        case OBASectionTypeNearbyRegions:
            if (self.nearbyRegion) {
                return 1;
            } else {
                return 0;
            }
        case OBASectionTypeCustomAPI:
            return 1;
		default:
			return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    OBASectionType sectionType = [self sectionTypeForSection:section];
    
    switch (sectionType) {
        case OBASectionTypeLoading:
            return NSLocalizedString(@"Loading available regions...", @"OBASectionTypeLoading title");
        case OBASectionTypeTitle:
            return NSLocalizedString(@"Select the region where you wish to use OneBusAway", @"OBASectionTypeTitle title");
        case OBASectionTypeNearbyRegions:
            return NSLocalizedString(@"Set Region automatically", @"OBASectionTypeNearbyRegions title");
        case OBASectionTypeAllRegions:
            return NSLocalizedString(@"Manually select Region", @"OBASectionTypeAllRegions title");
        case OBASectionTypeNoRegions:
            return NSLocalizedString(@"No regions found", @"OBASectionTypeNoRegions title");
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
        case OBASectionTypeCustomAPI:
            return [self customAPICellForRowAtIndexPath:indexPath tableView:tableView];
		default:
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    

	if( [self isLoading] ) {
		return;
	}
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeAllRegions:
			[self didSelectRegionRowAtIndexPath:indexPath tableView:tableView];
			break;
        case OBASectionTypeNearbyRegions:
            [self didSelectRegionRowAtIndexPath:indexPath tableView:tableView];
            break;
        case OBASectionTypeCustomAPI:
            [self didSelectCustomAPIRowAtIndexPath:indexPath tableView:tableView];
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

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	
    if (_regions == nil) {
        if (section == 0)
            return OBASectionTypeLoading;
        else if (section == 1)
            return OBASectionTypeCustomAPI;
    }
	else if( [_regions count] == 0 ) {
		if( section == 0 )
			return OBASectionTypeNoRegions;
        else if (section == 1)
            return OBASectionTypeCustomAPI;
	}
	else {
		if( section == 0 )
            return OBASectionTypeTitle;
        else if (self.nearbyRegion == nil) {
            if (section == 1)
                return OBASectionTypeAllRegions;
            else if (section == 2)
                return OBASectionTypeCustomAPI;
        }
        else {
            if (section == 1)
                return OBASectionTypeNearbyRegions;
            else if (section == 2)
                return OBASectionTypeAllRegions;
            else if (section == 3)
                return OBASectionTypeCustomAPI;
        }
	}
	
	return OBASectionTypeNone;
}

- (UITableViewCell*) regionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    OBARegionV2 *region = nil;
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    switch ([self sectionTypeForSection:indexPath.section]) {
        case OBASectionTypeNearbyRegions:
            region = self.nearbyRegion;
            if ([_appContext.modelDao readSetRegionAutomatically]) {
                self.checkedItem = indexPath;
            }
            break;
        case OBASectionTypeAllRegions:
            region = [_regions objectAtIndex:indexPath.row];
            if (![_appContext.modelDao readSetRegionAutomatically] &&
                [_appContext.modelDao.region.regionName isEqualToString:region.regionName]) {
                self.checkedItem = indexPath;
            }
            break;
        default:
            return nil;
            break;
    }
	
    cell.accessoryType = self.checkedItem == indexPath ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.textLabel.textColor = [UIColor blackColor];
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	cell.textLabel.text = region.regionName;
	return cell;
}

- (void) didSelectRegionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
	OBARegionV2 * region = nil;
    [[tableView cellForRowAtIndexPath:self.checkedItem] setAccessoryType:UITableViewCellAccessoryNone];
    [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    self.checkedItem = indexPath;
    
    switch ([self sectionTypeForSection:indexPath.section]) {
        case OBASectionTypeNearbyRegions:
            region = self.nearbyRegion;
            [_appContext.modelDao writeSetRegionAutomatically:YES];
            break;
        case OBASectionTypeAllRegions:
            region = [_regions objectAtIndex:indexPath.row];
            [_appContext.modelDao writeSetRegionAutomatically:NO];
            break;
        default:
            return ;
            break;
    }
    [_appContext.modelDao writeCustomApiUrl:@""];
    [_appContext.modelDao setOBARegion:region];
    [_appContext regionSelected];

}

- (UITableViewCell*) customAPICellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.text = NSLocalizedString(@"Custom API Url", @"cell.textLabel.text");
    return cell;
}

- (void) didSelectCustomAPIRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *pushMe = [[OBACustomApiViewController alloc] initWithApplicationDelegate:self.appContext];
    [self.navigationController pushViewController:pushMe animated:YES];
}
@end
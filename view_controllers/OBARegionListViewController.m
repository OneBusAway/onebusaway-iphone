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
    OBASectionTypeShowExperimentalRegions,
} OBASectionType;

@interface OBARegionListViewController ()

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;
- (UITableViewCell*) regionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (void) didSelectRegionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (UITableViewCell*) customAPICellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (void) didSelectCustomAPIRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void) doNeedToUpdateRegionsList;
@end

@implementation OBARegionListViewController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate {
	if( self = [super initWithApplicationDelegate:appDelegate] ) {
		self.refreshable = NO;
		self.showUpdateTime = NO;
	}
	return self;
}

-(void) viewDidLoad {
    [super viewDidLoad];
	self.refreshable = NO;
	self.showUpdateTime = NO;
    self.progressLabel = NSLocalizedString(@"Regions", @"regions title");
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    _showExperimentalRegions = NO;
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"kOBAShowExperimentalRegionsDefaultsKey"])
        _showExperimentalRegions = [[NSUserDefaults standardUserDefaults]
                                 boolForKey: @"kOBAShowExperimentalRegionsDefaultsKey"];
    _toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [_toggleSwitch setOn: _showExperimentalRegions animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	self.navigationItem.title = NSLocalizedString(@"Select Region",@"self.navigationItem.title");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCompleteNetworkRequest) name:OBAApplicationDidCompleteNetworkRequestNotification object:nil];
    
    OBALocationManager *lm = _appDelegate.locationManager;
    if (lm.locationServicesEnabled) {
        _locationTimedOut = NO;
        [lm addDelegate:self];
        [lm startUpdatingLocation];
        
        _locationTimer = [NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(timeOutLocation:) userInfo:(self) repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:_locationTimer forMode:NSRunLoopCommonModes];
        
    } else {
        _locationTimedOut = YES;
    }

    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OBAApplicationDidCompleteNetworkRequestNotification object:nil];
    
	[_appDelegate.locationManager stopUpdatingLocation];
	[_appDelegate.locationManager removeDelegate:self];
    [_locationTimer invalidate];
}


- (void)dealloc {
	_regions = nil;
    _mostRecentLocation = nil;
    _locationTimer = nil;
    _toggleSwitch = nil;
}

- (BOOL) isLoading {
	return _regions == nil || (_mostRecentLocation == nil && !_locationTimedOut);
}

- (id<OBAModelServiceRequest>) handleRefresh {
	return [_appDelegate.modelService requestRegions:self withContext:nil];
}

- (void) handleData:(id)obj context:(id)context {
    OBAListWithRangeAndReferencesV2 * list = obj;
	_regions = [[NSMutableArray alloc] initWithArray:list.values];
    
    NSMutableArray *notSupportedRegions = [NSMutableArray array];
    for (id obj in _regions) {
        OBARegionV2 *region = (OBARegionV2 *)obj;
        if ((!region.supportsObaRealtimeApis || !region.active)
            || (region.experimental && !_showExperimentalRegions)) {
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
    [self handleRefresh];
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
    OBALocationManager * lm = _appDelegate.locationManager;
	CLLocation * newLocation = lm.currentLocation;
	_mostRecentLocation = newLocation;
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
        return 2;
    else if(_regions == nil)
        return 3;
    else if ([_regions count] == 0)
        return 3;
	else if( self.nearbyRegion == nil)
        return 4;
    else
        return 5;
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
        case OBASectionTypeShowExperimentalRegions:
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
            return NSLocalizedString(@"Set region automatically", @"OBASectionTypeNearbyRegions title");
        case OBASectionTypeAllRegions:
            return NSLocalizedString(@"Manually select region", @"OBASectionTypeAllRegions title");
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
        case OBASectionTypeShowExperimentalRegions:
            return [self experimentalRegionCellForRowAtIndexPath:indexPath tableView:tableView];
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
	
	if (! [_appDelegate.modelDao hideFutureLocationWarnings]) {
		[_appDelegate.modelDao setHideFutureLocationWarnings:TRUE];
		
		UIAlertView * view = [[UIAlertView alloc] init];
		view.title = NSLocalizedString(@"Location Services Disabled",@"view.title");
		view.message = NSLocalizedString(@"Location Services are disabled for this app. Some location-aware functionality will be missing.",@"view.message");
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
            return OBASectionTypeShowExperimentalRegions;
        else if (section == 2)
            return OBASectionTypeCustomAPI;
    }
	else if( [_regions count] == 0 ) {
		if( section == 0 )
			return OBASectionTypeNoRegions;
        else if (section == 1)
            return OBASectionTypeShowExperimentalRegions;
        else if (section == 2)
            return OBASectionTypeCustomAPI;
	}
	else {
		if( section == 0 )
            return OBASectionTypeTitle;
        else if (self.nearbyRegion == nil) {
            if (section == 1)
                return OBASectionTypeAllRegions;
            else if (section == 2)
                return OBASectionTypeShowExperimentalRegions;
            else if (section == 3)
                return OBASectionTypeCustomAPI;
        }
        else {
            if (section == 1)
                return OBASectionTypeNearbyRegions;
            else if (section == 2)
                return OBASectionTypeAllRegions;
            else if (section == 3)
                return OBASectionTypeShowExperimentalRegions;
            else if (section == 4)
                return OBASectionTypeCustomAPI;
        }
	}
	
	return OBASectionTypeNone;
}

- (UITableViewCell*) regionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    OBARegionV2 *region = nil;
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"RegionsCell"];

    switch ([self sectionTypeForSection:indexPath.section]) {
        case OBASectionTypeNearbyRegions:
            region = self.nearbyRegion;
            if ([_appDelegate.modelDao readSetRegionAutomatically]) {
                self.checkedItem = indexPath;
            }
            break;
        case OBASectionTypeAllRegions:
            region = [_regions objectAtIndex:indexPath.row];
            if (![_appDelegate.modelDao readSetRegionAutomatically] &&
                [_appDelegate.modelDao.region.regionName isEqualToString:region.regionName]) {
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
    cell.textLabel.font = [UIFont systemFontOfSize:18];

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
            [_appDelegate.modelDao writeSetRegionAutomatically:YES];
            break;
        case OBASectionTypeAllRegions:
            region = [_regions objectAtIndex:indexPath.row];
            [_appDelegate.modelDao writeSetRegionAutomatically:NO];
            break;
        default:
            return ;
            break;
    }
    [_appDelegate.modelDao writeCustomApiUrl:@""];
    [_appDelegate.modelDao setOBARegion:region];
    [_appDelegate regionSelected];

}

- (UITableViewCell*) experimentalRegionCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"ExperimentalRegionCell"];
    [_toggleSwitch addTarget:self
                     action:@selector(didSwitchStateOfToggle:)
           forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = [[UIView alloc] initWithFrame:_toggleSwitch.frame];
    [cell.accessoryView addSubview:_toggleSwitch];
    
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.textLabel.text = NSLocalizedString(@"Experimental Regions", @"cell.textLabel.text");
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell*) customAPICellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"CustomAPICell"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.textLabel.text = NSLocalizedString(@"Custom API URL", @"cell.textLabel.text");
    return cell;
}

- (void) didSwitchStateOfToggle:(UISwitch *)toggleSwitch {
    if (toggleSwitch.on)
    {
    
        UIAlertView *unstableRegionAlert = [[UIAlertView alloc] initWithTitle:@"Regions in beta"
                                                        message:@"Experimental regions may be unstable and without real-time info! Go ahead?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];
        [unstableRegionAlert show];
        
    } else {
        //if current region is beta, show alert; otherwise, just update list
        if (_appDelegate.modelDao.region.experimental){
            UIAlertView *currentRegionUnavailableAlert = [[UIAlertView alloc] initWithTitle:@"Discard current region?"
                                                         message:@"Your current experimental region won't be available! Go ahead?"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"OK", nil];
            [currentRegionUnavailableAlert show];
        } else {
            [self doNeedToUpdateRegionsList];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"OK"])
    {
        [self doNeedToUpdateRegionsList];
    } else if([title isEqualToString:@"Cancel"]) {
        if (_showExperimentalRegions) {
            [_toggleSwitch setOn: YES animated:NO];
        }
        else {
            [_toggleSwitch setOn: NO animated:NO];
        }
    }
}

- (void) doNeedToUpdateRegionsList {
    
    
    _showExperimentalRegions = !_showExperimentalRegions;
    
    if (_appDelegate.modelDao.region.experimental){
        
        //Change to automatic region if available
        if (self.nearbyRegion) {
            [_appDelegate.modelDao writeSetRegionAutomatically:YES];
            [_appDelegate.modelDao setOBARegion:self.nearbyRegion];
        }
        //Otherwise, set region to first in list
        else if(![self isLoading] && _regions.count > 0) {
            [_appDelegate.modelDao setOBARegion:[_regions objectAtIndex:0]];
        }
        //Set region to nil if list is empty
        else if (![self isLoading]) {
            UIAlertView *noAvailableRegionsAlert = [[UIAlertView alloc] initWithTitle:@"No Regions Found" message:@"No available regions were found, recheck your connection and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [_appDelegate.modelDao setOBARegion:nil];
            [noAvailableRegionsAlert show];
        }
    }

    [[NSUserDefaults standardUserDefaults] setBool:_showExperimentalRegions
                                            forKey:@"kOBAShowExperimentalRegionsDefaultsKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self handleRefresh];
}

- (void) didSelectCustomAPIRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *pushMe = [[OBACustomApiViewController alloc] initWithApplicationDelegate:self.appDelegate];
    [self.navigationController pushViewController:pushMe animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch ([self sectionTypeForSection:section]) {
        case OBASectionTypeAllRegions:
        case OBASectionTypeNearbyRegions:
        case OBASectionTypeLoading:
        case OBASectionTypeNoRegions:
            return 40;
        case OBASectionTypeTitle:
            return 70;
        default:
            return 30;
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    view.backgroundColor = [UIColor colorWithHue:(86./360.) saturation:0.68 brightness:0.67 alpha:0.1];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 290, 30)];
    title.font = [UIFont systemFontOfSize:18];
    title.backgroundColor = [UIColor clearColor];
    
    switch ([self sectionTypeForSection:section]) {
        case OBASectionTypeLoading:
            title.text = NSLocalizedString(@"Loading available regions...", @"OBASectionTypeLoading title");
            break;
        case OBASectionTypeTitle:
            title.text =  NSLocalizedString(@"Select the region where you wish to use OneBusAway", @"OBASectionTypeTitle title");
            title.frame = CGRectMake(15, 5, 290, 60);
            title.numberOfLines = 2;
            break;
        case OBASectionTypeNearbyRegions:
            title.text =  NSLocalizedString(@"Set Region automatically", @"OBASectionTypeNearbyRegions title");
            break;
        case OBASectionTypeAllRegions:
            title.text =  NSLocalizedString(@"Manually select Region", @"OBASectionTypeAllRegions title");
            break;
        case OBASectionTypeNoRegions:
            title.text =  NSLocalizedString(@"No regions found", @"OBASectionTypeNoRegions title");
            break;
        default:
            break;
    }
    [view addSubview:title];
    return view;
}
@end
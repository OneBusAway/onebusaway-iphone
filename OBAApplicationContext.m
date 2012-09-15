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

#import <SystemConfiguration/SystemConfiguration.h>

#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"
#import "OBALogger.h"

#import "OBASearchResultsMapViewController.h"
#import "OBABookmarksViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBASearchViewController.h"
#import "OBASearchController.h"
#import "OBAStopViewController.h"
#import "OBAContactUsViewController.h"
#import "OBAAgenciesListViewController.h"
#import "OBAStopIconFactory.h"

#import "OBAUserPreferencesMigration.h"
#import "IASKAppSettingsViewController.h"


static NSString * kOBAHiddenPreferenceSavedNavigationTargets = @"OBASavedNavigationTargets";
static NSString * kOBAHiddenPreferenceApplicationLastActiveTimestamp = @"OBAApplicationLastActiveTimestamp";
static NSString * kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";
static NSString * kOBAHiddenPreferenceTabOrder = @"OBATabOrder";

static NSString * kOBAPreferenceShowOnStartup = @"oba_show_on_start_preference";
static NSString * kOBADefaultApiServerName = @"api.onebusaway.org";

static const double kMaxTimeSinceApplicationTerminationToRestoreState = 15 * 60;

static const NSUInteger kTagMapView = 0;
static const NSUInteger kTagBookmarkView = 1;
static const NSUInteger kTagRecentView = 2;
static const NSUInteger kTagSearchView = 3;
static const NSUInteger kTagContactUsView = 4;
static const NSUInteger kTagSettingsView = 5;
static const NSUInteger kTagAgenciesView = 6;


@interface OBAApplicationContext ()

- (void) _constructUI;

- (void) _saveState;
- (void) _restoreState;
- (void) _restoreTabOrder:(NSUserDefaults*)userDefaults;
- (BOOL) _shouldRestoreStateToDefault:(NSUserDefaults*)userDefaults;
- (void) _restoreStateToDefault:(NSUserDefaults*)userDefaults;
- (BOOL) _restoreSavedNavigationState:(NSUserDefaults*)userDefaults;

- (void) _navigateToTargetInternal:(OBANavigationTarget*)navigationTarget;

- (void) _setNavigationTarget:(OBANavigationTarget*)target forViewController:(UIViewController*)viewController;
- (UIViewController*) _getViewControllerForTarget:(OBANavigationTarget*)target;

- (NSInteger) _getViewControllerIndexForTag:(NSUInteger)tag;

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults;

- (void) _migrateUserPreferences;

- (NSString *)applicationDocumentsDirectory;

@end


@implementation OBAApplicationContext

- (id) init {
	if( self = [super init] ) {
		
		_active = NO;
		
		_references = [[OBAReferencesV2 alloc] init];
		_activityListeners = [[OBAActivityListeners alloc] init];
		_modelDao = [[OBAModelDAO alloc] init];
		_locationManager = [[OBALocationManager alloc] initWithModelDao:_modelDao];		
		
		[_activityListeners addListener:_modelDao];
		
		_modelService = [[OBAModelService alloc] init];
		_modelService.references = _references;
		_modelService.modelDao = _modelDao;
		
		OBAModelFactory * modelFactory = [[OBAModelFactory alloc] initWithReferences:_references];
		_modelService.modelFactory = modelFactory;
		
		_modelService.locationManager = _locationManager;
		
		_stopIconFactory = [[OBAStopIconFactory alloc] init];
		
		[self refreshSettings];
	}
	return self;
}


- (void) navigateToTarget:(OBANavigationTarget*)navigationTarget {
	[self performSelector:@selector(_navigateToTargetInternal:) withObject:navigationTarget afterDelay:0];
}

- (void) refreshSettings {
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
									
	NSString * apiServerName = [userDefaults objectForKey:@"oba_api_server"];
	if( apiServerName == nil || [apiServerName length] == 0 )
		apiServerName = kOBADefaultApiServerName;
	
	apiServerName = [NSString stringWithFormat:@"http://%@",apiServerName];
	
	NSString * userId = [self userIdFromDefaults:userDefaults];
	NSString * appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString * obaArgs = [NSString stringWithFormat:@"key=org.onebusaway.iphone&app_uid=%@&app_ver=%@",userId,appVersion];
	
	OBADataSourceConfig * obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:apiServerName args:obaArgs];	
	OBAJsonDataSource * obaJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:obaDataSourceConfig];
	_modelService.obaJsonDataSource = obaJsonDataSource;
	
	OBADataSourceConfig * googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://maps.google.com" args:@"output=json&oe=utf-8&key=ABQIAAAA1R_R0bUhLYRwbQFpKHVowhRAXGY6QyK0faTs-0G7h9EE_iri4RRtKgRdKFvvraEP5PX_lP_RlqKkzA"];
	OBAJsonDataSource * googleMapsJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:googleMapsDataSourceConfig];
	_modelService.googleMapsJsonDataSource = googleMapsJsonDataSource;
	
	[userDefaults setObject:appVersion forKey:@"oba_application_version"];
}

- (void)_constructUI
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.tabBarController = [[UITabBarController alloc] init];
    
    NSMutableArray *viewControllers = [NSMutableArray array];
    NSMutableArray *navigableVCs = [NSMutableArray array];
    
    self.mapViewController = [[OBASearchResultsMapViewController alloc] init];
    [viewControllers addObject:self.mapViewController];
    
    self.bookmarksViewController = [[OBABookmarksViewController alloc] init];
    [viewControllers addObject:self.bookmarksViewController];
    
    self.recentViewController = [[OBARecentStopsViewController alloc] init];
    [viewControllers addObject:self.recentViewController];
    
    self.searchViewController = [[OBASearchViewController alloc] init];
    [viewControllers addObject:self.searchViewController];
    
    self.contactViewController = [[OBAContactUsViewController alloc] init];
    [viewControllers addObject:self.contactViewController];
    
    self.settingsViewController = [[IASKAppSettingsViewController alloc] init];
    self.settingsViewController.title = NSLocalizedString(@"Settings", @"");
    self.settingsViewController.tabBarItem.image = [UIImage imageNamed:@"Gear"];
    [viewControllers addObject:self.settingsViewController];
    self.settingsViewController.delegate = self;
    
    self.agenciesViewController = [[OBAAgenciesListViewController alloc] init];
    [viewControllers addObject:self.agenciesViewController];
    
    // TODO: these shouldn't all need references to the app delegate.
    for (UIViewController *vc in viewControllers) {
        if ([vc respondsToSelector:@selector(setAppContext:)]) {
            [vc performSelector:@selector(setAppContext:) withObject:self];
        }
        
        [navigableVCs addObject:[[UINavigationController alloc] initWithRootViewController:vc]];
    }
    
    self.tabBarController.delegate = self;
    self.tabBarController.viewControllers = navigableVCs;
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
}

#pragma mark UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self _migrateUserPreferences];
    [self _constructUI];
	[self _restoreState];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	_active = YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	_active = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	
    CLLocation * location = _locationManager.currentLocation;
	if( location )
		_modelDao.mostRecentLocation = location;
	
	[self _saveState];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];

	/**
	 * If we've been in the background for a while (>15 mins), we restore
	 * the app to the user's preferred default state
	 */
	if( [self _shouldRestoreStateToDefault:userDefaults] )
		[self _restoreStateToDefault:userDefaults];
	
	
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self applicationDidEnterBackground:application]; // call for iOS < 4.0 devices
}

#pragma mark UITabBarControllerDelegate Methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
	
	NSLog(@"title=%@",viewController.title);
	if ([viewController.title isEqual:@"Agencies"] ) {
		/**
		 * Note that we delay the call to allow the tab-bar to finish its thing
		 */
		OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchAgenciesWithCoverage];
		[self performSelector:@selector(_navigateToTargetInternal:) withObject:target afterDelay:0];
		return NO;
	}
	
	return YES;
}

/**
 * We want to revert back to the root view of a selected controller when switching between tabs
 */
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	UINavigationController * nc = (UINavigationController *) viewController;
	/**
	 * Note that popToRootViewController didn't seem to work properly when called from the
	 * calling context of the UITabBarController.  So we punt it to the main thread.
	 */
	[nc performSelector:@selector(popToRootViewController) withObject:nil afterDelay:0];
}

/**
 * We want to save the tab order
 */
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
	
	NSUInteger count = tabBarController.viewControllers.count;
	NSMutableArray *tabOrderArray = [[NSMutableArray alloc] initWithCapacity:count];
	for (UIViewController *viewController in viewControllers) {		
		NSInteger tag = viewController.tabBarItem.tag;
		[tabOrderArray addObject:@(tag)];
	}
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:tabOrderArray forKey:kOBAHiddenPreferenceTabOrder];
	[userDefaults synchronize];
	
}

#pragma mark IASKSettingsDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
	[self refreshSettings];
}


- (void) _saveState {
	
	UINavigationController * navController = (UINavigationController*) self.tabBarController.selectedViewController;
	
	NSMutableArray * targets = [[NSMutableArray alloc] init];
	
	for( id source in [navController viewControllers] ) {
		if( ! [source conformsToProtocol:@protocol(OBANavigationTargetAware)] )
			break;
		id<OBANavigationTargetAware> targetSource = (id<OBANavigationTargetAware>) source;
		OBANavigationTarget * target = targetSource.navigationTarget;
		if( ! target )
			break;
		[targets addObject:target];
	}
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:targets];
	[userDefaults setObject:data forKey:kOBAHiddenPreferenceSavedNavigationTargets];
	
	NSDate * date = [NSDate date];
    NSData * dateData = [NSKeyedArchiver archivedDataWithRootObject:date];
	[userDefaults setObject:dateData forKey:kOBAHiddenPreferenceApplicationLastActiveTimestamp];
	
	
	[userDefaults synchronize];
}

- (void) _restoreState {
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	[self _restoreTabOrder:userDefaults];
	
	if( [self _shouldRestoreStateToDefault:userDefaults] ) {
		[self _restoreStateToDefault:userDefaults];
		return;
	}

	if( [self _restoreSavedNavigationState:userDefaults] )
		return;

	// If we had no default state, just use a reasonable default
	self.tabBarController.selectedIndex = 0;
}

- (void) _restoreTabOrder:(NSUserDefaults*)userDefaults {
	/**
	 * Restore tab order if necessary
	 */
	NSArray *initialViewControllers = [NSArray arrayWithArray:self.tabBarController.viewControllers];
    NSArray *tabBarOrder = [userDefaults objectForKey:kOBAHiddenPreferenceTabOrder];
	
    if (tabBarOrder) {
        NSMutableArray *newViewControllers = [NSMutableArray arrayWithCapacity:initialViewControllers.count];
        for (NSNumber *tabBarNumber in tabBarOrder) {
            NSUInteger tabBarIndex = [tabBarNumber unsignedIntegerValue];
            [newViewControllers addObject:initialViewControllers[tabBarIndex]];
        }
        self.tabBarController.viewControllers = newViewControllers;
    }	
	
	/**
	 * For now, we don't allow the customization of tab order
	 */
	self.tabBarController.customizableViewControllers = @[];
}

- (BOOL) _shouldRestoreStateToDefault:(NSUserDefaults*)userDefaults {

	// We should only restore the application state if it's been less than x minutes
	// The idea is that, typically, if it's been more than x minutes, you've moved
	// on from the stop you were looking at, so we should just return to the users'
	// preferred home screen
	
	NSData * dateData = [userDefaults objectForKey:kOBAHiddenPreferenceApplicationLastActiveTimestamp];
	if( ! dateData ) 
		return YES;
	NSDate * date = [NSKeyedUnarchiver unarchiveObjectWithData:dateData];
	if( ! date || (-[date timeIntervalSinceNow]) > kMaxTimeSinceApplicationTerminationToRestoreState )
		return YES;
	
	return NO;
}

- (void) _restoreStateToDefault:(NSUserDefaults*)userDefaults {
	NSInteger showOnStartup = [userDefaults integerForKey:kOBAPreferenceShowOnStartup];
	if( 0 <= showOnStartup && showOnStartup < 4 )
		self.tabBarController.selectedIndex = showOnStartup;
}

- (BOOL) _restoreSavedNavigationState:(NSUserDefaults*)userDefaults {
	
	NSData *restoreStateData = [userDefaults objectForKey:kOBAHiddenPreferenceSavedNavigationTargets];
	
	if(!restoreStateData)
		return NO;
	
	NSArray * targets = [NSKeyedUnarchiver unarchiveObjectWithData:restoreStateData];
	
	if(!targets || [targets count] == 0)
		return NO;
	
	OBANavigationTarget * rootTarget = targets[0];
	NSInteger selectedTag = -1;
	
	switch(rootTarget.target) {
		case OBANavigationTargetTypeSearchResults:
			selectedTag = kTagMapView;
			break;
		case OBANavigationTargetTypeBookmarks:
			selectedTag = kTagBookmarkView;
			break;
		case OBANavigationTargetTypeRecentStops:
			selectedTag = kTagRecentView;
			break;
		case OBANavigationTargetTypeSearch:
			selectedTag = kTagSearchView;
			break;
		case OBANavigationTargetTypeContactUs:
			selectedTag = kTagContactUsView;
			break;
		case OBANavigationTargetTypeSettings:
			selectedTag = kTagSettingsView;
			break;
		case OBANavigationTargetTypeAgencies:
			selectedTag = kTagAgenciesView;
			break;
		default:
			return NO;
	}
	
	if( selectedTag == -1 )
		return NO;
	
	NSInteger index = [self _getViewControllerIndexForTag:selectedTag];
	if( index == -1 )
		return NO;
	
	self.tabBarController.selectedIndex = index;
	
	UINavigationController * rootNavController = (UINavigationController*) self.tabBarController.selectedViewController;
	
	UIViewController * rootViewController = [rootNavController topViewController];
	
	[self _setNavigationTarget:rootTarget forViewController:rootViewController];
	
	for( NSUInteger index = 1; index < [targets count]; index++) {
		OBANavigationTarget * nextTarget = targets[index];
		UIViewController * nextViewController = [self _getViewControllerForTarget:nextTarget];
		if( ! nextViewController )
			break;		
		[self _setNavigationTarget:nextTarget forViewController:nextViewController];
		[rootNavController pushViewController:nextViewController animated:YES];
	}
	
	return YES;
}

- (void) _navigateToTargetInternal:(OBANavigationTarget*)navigationTarget {
	
	[_references clear];
	
	UINavigationController * current = (UINavigationController*) self.tabBarController.selectedViewController;
	if( current )
		[current popToRootViewControllerAnimated:NO];
	
	switch (navigationTarget.target) {
		case OBANavigationTargetTypeSearchResults: {
			NSInteger index = [self _getViewControllerIndexForTag:kTagMapView];
			if( index == -1 )
				return;
			UINavigationController * mapNavController = (self.tabBarController.viewControllers)[index];

			OBASearchResultsMapViewController * searchResultsMapViewController = (mapNavController.viewControllers)[0];
			[searchResultsMapViewController setNavigationTarget:navigationTarget];
			
			self.tabBarController.selectedIndex = index;
			[mapNavController popToRootViewControllerAnimated:NO];
			
			break;
		}
			
//		case OBANavigationTargetTypeContactUs: {
//			NSInteger index = [self _getViewControllerIndexForTag:kTagContactUsView];
//			if( index == -1 )
//				return;
//			UINavigationController * detailsNavController = (self.tabBarController.viewControllers)[index];
//			[detailsNavController popToRootViewControllerAnimated:NO];
//			OBAContactUsViewController * vc = [[OBAContactUsViewController alloc] initWithApplicationContext:self];
//			[detailsNavController pushViewController:vc animated:NO];
//			self.tabBarController.selectedIndex = index;
//			break;
//		}

        default: {
            NSLog(@"Unhandled switch case in %s: %d", __PRETTY_FUNCTION__, navigationTarget.target);
        }
	}
}

- (void) _setNavigationTarget:(OBANavigationTarget*)target forViewController:(UIViewController*)viewController {
	if( ! [viewController conformsToProtocol:@protocol(OBANavigationTargetAware) ] )
		return;
    
	if( ! [viewController respondsToSelector:@selector(setNavigationTarget:) ] )
		return;
	
	id<OBANavigationTargetAware> targetAware = (id<OBANavigationTargetAware>) viewController;
	[targetAware setNavigationTarget:target];
}

- (UIViewController*) _getViewControllerForTarget:(OBANavigationTarget*)target {
	
	switch (target.target) {
		case OBANavigationTargetTypeStop:
			return [[OBAStopViewController alloc] initWithApplicationContext:self];
//		case OBANavigationTargetTypeContactUs:
//			return [[OBAContactUsViewController alloc] initWithApplicationContext:self];
        default:
            return nil;
	}
}

- (NSInteger) _getViewControllerIndexForTag:(NSUInteger)tag {
	
	NSArray * controllers = self.tabBarController.viewControllers;
	NSUInteger count = [controllers count];
	
	for( NSUInteger i=0; i<count; i++ ) {
		UINavigationController * nc = controllers[i];
		if( nc.tabBarItem.tag == tag )
			return i;
	}
	
	return -1;	
}

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults {
	
	NSString * userId = [userDefaults stringForKey:kOBAHiddenPreferenceUserId];
	
	if( ! userId) {
		CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
		if (theUUID) {
			userId = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
			CFRelease(theUUID);
			[userDefaults setObject:userId forKey:kOBAHiddenPreferenceUserId];
			[userDefaults synchronize];
		}
		else {
			userId = @"anonymous";
		}
	}
	
	return userId;
}

- (void) _migrateUserPreferences {
	
	OBAUserPreferencesMigration * migration = [[OBAUserPreferencesMigration alloc] init];
	
	NSString * path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"OneBusAway.sqlite"];
	[migration migrateCoreDataPath:path toDao:_modelDao];
}

#pragma mark Application's documents directory

/**
 * Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? paths[0] : nil;
	return basePath;
}

@end


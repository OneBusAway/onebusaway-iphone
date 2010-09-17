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

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <SystemConfiguration/SystemConfiguration.h>

#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"
#import "OBALogger.h"

#import "OBASearchResultsMapViewController.h"
#import "OBABookmarksViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBASearchViewController.h"
#import "OBASearchController.h"
#import "OBASettingsViewController.h"
#import "OBAStopViewController.h"
#import "OBAContactUsViewController.h"

#import "OBAStopIconFactory.h"

#import "OBAUserPreferencesMigration.h"


static NSString * kOBAHiddenPreferenceSavedNavigationTargets = @"OBASavedNavigationTargets";
static NSString * kOBAHiddenPreferenceApplicationLastActiveTimestamp = @"OBAApplicationLastActiveTimestamp";
static NSString * kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";

static NSString * kOBAPreferenceShowOnStartup = @"oba_show_on_start_preference";
static NSString * kOBADefaultApiServerName = @"api.onebusaway.org";

static const double kMaxTimeSinceApplicationTerminationToRestoreState = 15 * 60;


@interface OBAApplicationContext (Private)

- (void) saveState;

- (void) restoreState;
- (BOOL) shouldRestoreStateToDefault:(NSUserDefaults*)userDefaults;
- (void) restoreStateToDefault:(NSUserDefaults*)userDefaults;
- (BOOL) restoreSavedNavigationState:(NSUserDefaults*)userDefaults;

- (void) navigateToTargetInternal:(OBANavigationTarget*)navigationTarget;

- (void) setNavigationTarget:(OBANavigationTarget*)target forViewController:(UIViewController*)viewController;
- (UIViewController*) getViewControllerForTarget:(OBANavigationTarget*)target;

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults;

- (void) migrateUserPreferences;

- (NSString *)applicationDocumentsDirectory;

@end


@implementation OBAApplicationContext

@synthesize references = _references;
@synthesize locationManager = _locationManager;
@synthesize activityListeners = _activityListeners;

@synthesize modelDao = _modelDao;
@synthesize modelService = _modelService;

@synthesize stopIconFactory = _stopIconFactory;

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

@synthesize active = _active;

- (id) init {
	if( self = [super init] ) {
		
		_active = FALSE;
		
		_references = [[OBAReferencesV2 alloc] init];
		_locationManager = [[OBALocationManager alloc] init];		
		_activityListeners = [[OBAActivityListeners alloc] init];
		_modelDao = [[OBAModelDAO alloc] init];
		
		
		[_activityListeners addListener:_modelDao];
		
		_modelService = [[OBAModelService alloc] init];
		_modelService.references = _references;
		_modelService.modelDao = _modelDao;
		
		OBAModelFactory * modelFactory = [[OBAModelFactory alloc] initWithReferences:_references];
		_modelService.modelFactory = modelFactory;
		[modelFactory release];
		
		_modelService.locationManager = _locationManager;
		
		_stopIconFactory = [[OBAStopIconFactory alloc] init];
		
		[self refreshSettings];
	}
	return self;
}

- (void) dealloc {
	[_modelDao release];
	[_modelService release];
	[_references release];
	
	[_locationManager release];
	[_activityListeners release];
	
	[_stopIconFactory release];
	
	[_window release];
	[_tabBarController release];
	
	[super dealloc];
}

- (void) navigateToTarget:(OBANavigationTarget*)navigationTarget {
	[self performSelector:@selector(navigateToTargetInternal:) withObject:navigationTarget afterDelay:0];
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
	[obaJsonDataSource release];
	[obaDataSourceConfig release];
	
	OBADataSourceConfig * googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://maps.google.com" args:@"output=json&oe=utf-8&key=ABQIAAAA1R_R0bUhLYRwbQFpKHVowhRAXGY6QyK0faTs-0G7h9EE_iri4RRtKgRdKFvvraEP5PX_lP_RlqKkzA"];
	OBAJsonDataSource * googleMapsJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:googleMapsDataSourceConfig];
	_modelService.googleMapsJsonDataSource = googleMapsJsonDataSource;
	[googleMapsJsonDataSource release];
	[googleMapsDataSourceConfig release];
}

#pragma mark UIApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	
	[self migrateUserPreferences];
	
	_tabBarController.delegate = self;
	
	UIView * rootView = [_tabBarController view];
	[_window addSubview:rootView];
	[_window makeKeyAndVisible];
	
	[self restoreState];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	_active = TRUE;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	_active = FALSE;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    CLLocation * location = _locationManager.currentLocation;
	if( location )
		_modelDao.mostRecentLocation = location;
	
	[self saveState];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];

	/**
	 * If we've been in the background for a while (>15 mins), we restore
	 * the app to the user's preferred default state
	 */
	if( [self shouldRestoreStateToDefault:userDefaults] )
		[self restoreStateToDefault:userDefaults];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self applicationDidEnterBackground:application]; // call for iOS < 4.0 devices
}

#pragma mark UITabBarControllerDelegate Methods

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

@end

@implementation OBAApplicationContext (Private)

- (void) saveState {
	
	UINavigationController * navController = (UINavigationController*) _tabBarController.selectedViewController;
	
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
	
	[targets release];
	
	[userDefaults synchronize];
}

- (void) restoreState {
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	if( [self shouldRestoreStateToDefault:userDefaults] ) {
		[self restoreStateToDefault:userDefaults];
		return;
	}

	if( [self restoreSavedNavigationState:userDefaults] )
		return;

	// If we had no default state, just use a reasonable default
	_tabBarController.selectedIndex = 0;
}

- (BOOL) shouldRestoreStateToDefault:(NSUserDefaults*)userDefaults {

	// We should only restore the application state if it's been less than x minutes
	// The idea is that, typically, if it's been more than x minutes, you've moved
	// on from the stop you were looking at, so we should just return to the users'
	// preferred home screen
	
	NSData * dateData = [userDefaults objectForKey:kOBAHiddenPreferenceApplicationLastActiveTimestamp];
	if( ! dateData ) 
		return TRUE;
	NSDate * date = [NSKeyedUnarchiver unarchiveObjectWithData:dateData];
	if( ! date || (-[date timeIntervalSinceNow]) > kMaxTimeSinceApplicationTerminationToRestoreState )
		return TRUE;
	
	return FALSE;
}

- (void) restoreStateToDefault:(NSUserDefaults*)userDefaults {
	NSInteger showOnStartup = [userDefaults integerForKey:kOBAPreferenceShowOnStartup];
	if( 0 <= showOnStartup && showOnStartup < 4 )
		_tabBarController.selectedIndex = showOnStartup;
}

- (BOOL) restoreSavedNavigationState:(NSUserDefaults*)userDefaults {
	
	NSData *restoreStateData = [userDefaults objectForKey:kOBAHiddenPreferenceSavedNavigationTargets];
	
	if(!restoreStateData)
		return FALSE;
	
	NSArray * targets = [NSKeyedUnarchiver unarchiveObjectWithData:restoreStateData];
	
	if(!targets || [targets count] == 0)
		return FALSE;
	
	OBANavigationTarget * rootTarget = [targets objectAtIndex:0];
	
	switch(rootTarget.target) {
		case OBANavigationTargetTypeSearchResults:
			_tabBarController.selectedIndex = 0;
			break;
		case OBANavigationTargetTypeBookmarks:
			_tabBarController.selectedIndex = 1;
			break;
		case OBANavigationTargetTypeRecentStops:
			_tabBarController.selectedIndex = 2;
			break;
		case OBANavigationTargetTypeSearch:
			_tabBarController.selectedIndex = 3;
			break;
		case OBANavigationTargetTypeSettings:
			_tabBarController.selectedIndex = 4;
			break;
		default:
			return FALSE;
	}
	
	UINavigationController * rootNavController = (UINavigationController*) _tabBarController.selectedViewController;
	
	UIViewController * rootViewController = [rootNavController topViewController];
	
	[self setNavigationTarget:rootTarget forViewController:rootViewController];
	
	for( NSUInteger index = 1; index < [targets count]; index++) {
		OBANavigationTarget * nextTarget = [targets objectAtIndex:index];
		UIViewController * nextViewController = [self getViewControllerForTarget:nextTarget];
		if( ! nextViewController )
			break;		
		[self setNavigationTarget:nextTarget forViewController:nextViewController];
		[rootNavController pushViewController:nextViewController animated:TRUE];
		[nextViewController release];
	}
	
	return TRUE;
}

- (void) navigateToTargetInternal:(OBANavigationTarget*)navigationTarget {
	
	[_references clear];
	
	UINavigationController * current = (UINavigationController*) _tabBarController.selectedViewController;
	if( current )
		[current popToRootViewControllerAnimated:FALSE];
	
	switch (navigationTarget.target) {
		case OBANavigationTargetTypeSearchResults: {
			UINavigationController * mapNavController = [_tabBarController.viewControllers objectAtIndex:0];

			OBASearchResultsMapViewController * searchResultsMapViewController = [mapNavController.viewControllers objectAtIndex:0];
			[searchResultsMapViewController setNavigationTarget:navigationTarget];
			
			_tabBarController.selectedIndex = 0;
			[mapNavController popToRootViewControllerAnimated:FALSE];
			
			break;
		}
			
		case OBANavigationTargetTypeContactUs: {
			UINavigationController * detailsNavController = [_tabBarController.viewControllers objectAtIndex:4];
			[detailsNavController popToRootViewControllerAnimated:FALSE];
			OBAContactUsViewController * vc = [[OBAContactUsViewController alloc] initWithApplicationContext:self];
			[detailsNavController pushViewController:vc animated:FALSE];
			[vc release];
			_tabBarController.selectedIndex = 4;
			break;
		}
	}	
}

- (void) setNavigationTarget:(OBANavigationTarget*)target forViewController:(UIViewController*)viewController {
	if( ! [viewController conformsToProtocol:@protocol(OBANavigationTargetAware) ] )
		return;
    
	if( ! [viewController respondsToSelector:@selector(setNavigationTarget:) ] )
		return;
	
	id<OBANavigationTargetAware> targetAware = (id<OBANavigationTargetAware>) viewController;
	[targetAware setNavigationTarget:target];
}

- (UIViewController*) getViewControllerForTarget:(OBANavigationTarget*)target {
	
	switch(target.target) {
		case OBANavigationTargetTypeStop:
			return [[OBAStopViewController alloc] initWithApplicationContext:self];
		case OBANavigationTargetTypeContactUs:
			return [[OBAContactUsViewController alloc] initWithApplicationContext:self];
	}
	
	return nil;
}

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults {
	
	NSString * userId = [userDefaults stringForKey:kOBAHiddenPreferenceUserId];
	
	if( ! userId) {
		CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
		if (theUUID) {
			userId = NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
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

- (void) migrateUserPreferences {
	
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
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	return basePath;
}

@end


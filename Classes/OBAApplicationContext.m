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

#import "OBAActivityLoggingViewController.h"
#import "OBAActivityAnnotationViewController.h"
#import "OBAUploadViewController.h"
#import "OBALockViewController.h"

#import "OBANearbyTripsController.h"
#import "OBAUserPreferencesMigration.h"


static NSString * kOBAHiddenPreferenceLocationAwareDisabled = @"OBALocationAwareDisabled";
static NSString * kOBAHiddenPreferenceSavedNavigationTargets = @"OBASavedNavigationTargets";
static NSString * kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";

static NSString* kOBAApiServerName = @"http://api.onebusaway.org";
static NSInteger kOBADefaultShowOnStartup = 0; // 0 = maps screen


@interface OBAApplicationContext (Private)

- (void) setup;
- (void) teardown;

- (void) saveApplicationNavigationState;
- (void) restoreApplicationNavigationState;

- (void) setNavigationTarget:(OBANavigationTarget*)target forViewController:(UIViewController*)viewController;
- (UIViewController*) getViewControllerForTarget:(OBANavigationTarget*)target;

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults;

- (void) migrateUserPreferences;

- (NSString *)applicationDocumentsDirectory;

@end


@implementation OBAApplicationContext

@synthesize locationManager = _locationManager;
@synthesize activityListeners = _activityListeners;

@synthesize obaDataSourceConfig = _obaDataSourceConfig;
@synthesize googleMapsDataSourceConfig = _googleMapsDataSourceConfig;

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

@synthesize active = _active;
@synthesize locationAware = _locationAware;

- (id) init {
	if( self = [super init] ) {

		_setup = FALSE;
		_active = FALSE;
		_locationAware = TRUE;
		
		_references = [[OBAReferencesV2 alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_modelDao release];
	[_modelService release];
	[_references release];
	
	[_locationManager release];
	[_nearbyTripsController release];
	[_activityListeners release];
	
	[_obaDataSourceConfig release];
	[_googleMapsDataSourceConfig release];
	
	if( kIncludeUWActivityInferenceCode )
		[_activityLogger release];
	
	[_window release];
	[_tabBarController release];
	
	[super dealloc];
}

- (void) navigateToTarget:(OBANavigationTarget*)navigationTarget {
	
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

- (OBAModelDAO*) modelDao {
	if( ! _modelDao )
		[self setup];
	return _modelDao;
}

- (OBAModelFactory*) modelFactory {
	if( ! _modelFactory )
		[self setup];
	return _modelFactory;
}

- (OBAModelService*) modelService {
	if( ! _modelService )
		[self setup];
	return _modelService;
}

#pragma mark UIApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	[self setup];
	
	_tabBarController.delegate = self;

	UIView * rootView = [_tabBarController view];
	[_window addSubview:rootView];
	[_window makeKeyAndVisible];
	
	OBANavigationTarget * navTarget = [OBASearchControllerFactory getNavigationTargetForSearchNone];
	[self navigateToTarget:navTarget];
	
	[self restoreApplicationNavigationState];
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
	
	[self saveApplicationNavigationState];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self applicationDidEnterBackground:application]; // call for iOS < 4.0 devices
	[self teardown];
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

- (void) setup {
	if( _setup )
		return;
	
	_setup = TRUE;
	_active = TRUE;
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSString * userId = [self userIdFromDefaults:userDefaults];
	NSString * appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString * obaArgs = [NSString stringWithFormat:@"key=org.onebusaway.iphone&app_uid=%@&app_ver=%@",userId,appVersion];

	_obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:kOBAApiServerName args:obaArgs];		
	
	//_obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://localhost:8080/onebusaway-api-webapp" args:@"key=org.onebusaway.iphone"];
	_googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://maps.google.com" args:@"output=json&oe=utf-8&key=ABQIAAAA1R_R0bUhLYRwbQFpKHVowhRAXGY6QyK0faTs-0G7h9EE_iri4RRtKgRdKFvvraEP5PX_lP_RlqKkzA"];
	
	_locationManager = [[OBALocationManager alloc] init];		
	_activityListeners = [[OBAActivityListeners alloc] init];		
	
	if( kIncludeUWActivityInferenceCode ) {
		_activityLogger = [[OBAActivityLogger alloc] init];
		_activityLogger.context = self;
		_nearbyTripsController = [[OBANearbyTripsController alloc] initWithApplicationContext:self];
	}

	if( kIncludeUWUserStudyCode ) {
		_locationAware = ! [userDefaults boolForKey:kOBAHiddenPreferenceLocationAwareDisabled];
	}
	
	_modelDao = [[OBAModelDAO alloc] init];
	
	[_activityListeners addListener:_modelDao];
	
	_modelFactory = [[OBAModelFactory alloc] initWithReferences:_references];
	
	if( kIncludeUWActivityInferenceCode ) {
		[_activityLogger start];
		if( kIncludeUWActivityNearbyTripLogging ) {
			[_nearbyTripsController start];
		}
	}
	
	_modelService = [[OBAModelService alloc] initWithReferences:_references modelFactory:_modelFactory dataSourceConfig:_obaDataSourceConfig];
	
	[self migrateUserPreferences];
}

- (void) teardown {	
	if( kIncludeUWActivityInferenceCode ) {
		if( kIncludeUWActivityNearbyTripLogging ) {
			[_nearbyTripsController stop];
		}
		[_activityLogger stop];
	}

	if( _locationAware )
		[_locationManager stopUpdatingLocation];
}	

- (void) saveApplicationNavigationState {
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
	
    //NSData *dateData = [NSKeyedArchiver archivedDataWithRootObject:[NSDate date]];
	//[userDefaults setObject:dateData forKey:kOBAHiddenPreferenceApplicationTerminationTimestamp];
	
    if( kIncludeUWUserStudyCode )
		[userDefaults setBool:(!_locationAware) forKey:kOBAHiddenPreferenceLocationAwareDisabled];

	[targets release];	
}

- (void) restoreApplicationNavigationState {
    _tabBarController.selectedIndex = kOBADefaultShowOnStartup;
    
    // On iOS 4.0 the default expectaton is that state will be restored, so
    // we no longer check if we should restore state and instead do it
    // consistently.
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSData *restoreStateData = [userDefaults objectForKey:kOBAHiddenPreferenceSavedNavigationTargets];
	
	if(!restoreStateData)
		return;
	
	NSArray * targets = [NSKeyedUnarchiver unarchiveObjectWithData:restoreStateData];

	if(!targets || [targets count] == 0)
		return;
	
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
			return;
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
		case OBANavigationTargetTypeActivityLogging:
			return [[OBAActivityLoggingViewController alloc] initWithApplicationContext:self];
		case OBANavigationTargetTypeActivityAnnotation:
			return [[OBAActivityAnnotationViewController alloc] initWithApplicationContext:self];
		case OBANavigationTargetTypeActivityUpload:
			return [[OBAUploadViewController alloc] initWithApplicationContext:self];
		case OBANavigationTargetTypeActivityLock:
			return [[OBALockViewController alloc] initWithApplicationContext:self];
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


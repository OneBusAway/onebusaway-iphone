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
#import "OBAApplicationDelegate.h"
#import "OBANavigationTargetAware.h"
#import "OBALogger.h"

#import "OBASearchResultsMapViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBABookmarksViewController.h"
#import "OBAInfoViewController.h"

#import "OBASearchController.h"
#import "OBAStopViewController.h"
#import "OBAStopIconFactory.h"

#import "OBAUserPreferencesMigration.h"

#import "OBARegionListViewController.h"
#import "OBARegionHelper.h"

static NSString * kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";
static NSString * kOBADefaultRegionApiServerName = @"regions.onebusaway.org";

@interface OBAApplicationDelegate ()
@property(nonatomic,readwrite) BOOL active;
@property(nonatomic) OBARegionHelper *regionHelper;


- (void) _constructUI;
- (void) _navigateToTargetInternal:(OBANavigationTarget*)navigationTarget;
- (void) _setNavigationTarget:(OBANavigationTarget*)target forViewController:(UIViewController*)viewController;
- (UIViewController*) _getViewControllerForTarget:(OBANavigationTarget*)target;

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults;
- (void) _migrateUserPreferences;
- (NSString *)applicationDocumentsDirectory;
@end

@implementation OBAApplicationDelegate

- (id)init {
    self = [super init];

    if (self) {

        self.active = NO;

        _references = [[OBAReferencesV2 alloc] init];
        _modelDao = [[OBAModelDAO alloc] init];
        _locationManager = [[OBALocationManager alloc] initWithModelDao:_modelDao];        
                
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

- (void)refreshSettings {
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *apiServerName = nil;
	if([self.modelDao.readCustomApiUrl isEqualToString:@""]) {
        if (_modelDao.region != nil) {
            apiServerName = [NSString stringWithFormat:@"%@", _modelDao.region.obaBaseUrl];
            // remove the last '/'
            apiServerName = [apiServerName substringToIndex:[apiServerName length]-1];
        }
        else {
            self.regionHelper = [[OBARegionHelper alloc] init];
            [self.modelDao writeSetRegionAutomatically:YES];
            [self.regionHelper updateNearestRegion];
            apiServerName = [NSString stringWithFormat:@"http://%@",apiServerName];
        }
        
    } else {
        apiServerName = [NSString stringWithFormat:@"http://%@",self.modelDao.readCustomApiUrl];
        if ([apiServerName hasSuffix:@"/"]) {
            apiServerName = [apiServerName substringToIndex:[apiServerName length]-1];
        }
    }
    NSLog(@"%@",apiServerName);

    
    NSString * userId = [self userIdFromDefaults:userDefaults];
    NSString * appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * obaArgs = [NSString stringWithFormat:@"key=org.onebusaway.iphone&app_uid=%@&app_ver=%@",userId,appVersion];
    
    OBADataSourceConfig * obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:apiServerName args:obaArgs];    
    OBAJsonDataSource * obaJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:obaDataSourceConfig];
    _modelService.obaJsonDataSource = obaJsonDataSource;
    
    OBADataSourceConfig * googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://maps.google.com" args:@"output=json&oe=utf-8&key=ABQIAAAA1R_R0bUhLYRwbQFpKHVowhRAXGY6QyK0faTs-0G7h9EE_iri4RRtKgRdKFvvraEP5PX_lP_RlqKkzA"];
    OBAJsonDataSource * googleMapsJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:googleMapsDataSourceConfig];
    _modelService.googleMapsJsonDataSource = googleMapsJsonDataSource;
    
    
    NSString * regionApiServerName = [userDefaults objectForKey:@"oba_region_api_server"];
    if (regionApiServerName == nil || [regionApiServerName length] == 0) {
        regionApiServerName = kOBADefaultRegionApiServerName;
    }
    
    regionApiServerName = [NSString stringWithFormat:@"http://%@", regionApiServerName];
    
    OBADataSourceConfig * obaRegionDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:regionApiServerName args:obaArgs];
    OBAJsonDataSource * obaRegionJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:obaRegionDataSourceConfig];
    _modelService.obaRegionJsonDataSource = obaRegionJsonDataSource;
    
    [userDefaults setObject:appVersion forKey:@"oba_application_version"];
}

- (void)_constructUI
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];

    self.tabBarController = [[UITabBarController alloc] init];

    self.mapViewController = [[OBASearchResultsMapViewController alloc] init];
    self.mapViewController.appContext = self;
    self.mapNavigationController = [[UINavigationController alloc] initWithRootViewController:self.mapViewController];
    
    self.recentsViewController = [[OBARecentStopsViewController alloc] init];
    self.recentsViewController.appContext = self;
    self.recentsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.recentsViewController];

    self.bookmarksViewController = [[OBABookmarksViewController alloc] init];
    self.bookmarksViewController.appContext = self;
    self.bookmarksNavigationController = [[UINavigationController alloc] initWithRootViewController:self.bookmarksViewController];
    
    self.infoViewController = [[OBAInfoViewController alloc] init];
    self.infoNavigationController = [[UINavigationController alloc] initWithRootViewController:self.infoViewController];

    self.tabBarController.viewControllers = @[self.mapNavigationController, self.recentsNavigationController, self.bookmarksNavigationController, self.infoNavigationController];

    self.tabBarController.selectedIndex = 0;
    
    UIColor *tintColor = [UIColor colorWithHue:(86./360.) saturation:0.68 brightness:0.67 alpha:1];
    [[UINavigationBar appearance] setTintColor:tintColor];
    [[UISearchBar appearance] setTintColor:tintColor];
    [[UISegmentedControl appearance] setTintColor:tintColor];
    [[UITabBar appearance] setSelectedImageTintColor:tintColor];
    
    self.window.rootViewController = self.tabBarController;
    
    if ([self.modelDao.readCustomApiUrl isEqualToString:@""]) {
        _regionHelper = [[OBARegionHelper alloc] init];
        if (self.modelDao.readSetRegionAutomatically) {
            [_regionHelper updateNearestRegion];
        } else {
            [_regionHelper updateRegion];
        }
    }



    [self.window makeKeyAndVisible];
}

#pragma mark UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self _migrateUserPreferences];
    [self _constructUI];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    CLLocation * location = _locationManager.currentLocation;
    if ( location )
    {
        _modelDao.mostRecentLocation = location;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self applicationDidEnterBackground:application]; // call for iOS < 4.0 devices
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.active = YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    self.active = NO;
}



/*
#pragma mark IASKSettingsDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    [self refreshSettings];
    
}
*/
- (void) _navigateToTargetInternal:(OBANavigationTarget*)navigationTarget {
    
    [_references clear];
    
    [self.mapNavigationController popToRootViewControllerAnimated:NO];
    
    if (OBANavigationTargetTypeSearchResults == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.mapNavigationController];
        self.mapViewController.navigationTarget = navigationTarget;
    }
    else if (OBANavigationTargetTypeContactUs == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.infoNavigationController];
        [self.infoViewController tableView:self.infoViewController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    else if (OBANavigationTargetTypeSettings == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.infoNavigationController];
        [self.infoViewController tableView:self.infoViewController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    }
    else if (OBANavigationTargetTypeAgencies == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.infoNavigationController];
        [self.infoViewController tableView:self.infoViewController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    }
    else if (OBANavigationTargetTypeBookmarks == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.bookmarksNavigationController];
    }
    else {
        NSLog(@"Unhandled target in %s: %d", __PRETTY_FUNCTION__, navigationTarget.target);
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
        default:
            return nil;
    }
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

- (void)regionSelected {
    [_regionListViewController.view removeFromSuperview];
    _regionListViewController = nil;
    
    [self refreshSettings];
    
    self.window.rootViewController = self.tabBarController;
    [_window makeKeyAndVisible];
}

- (void) showRegionListViewController
{
    _regionListViewController = [[OBARegionListViewController alloc] initWithApplicationContext:self];
    self.window.rootViewController = _regionListViewController;
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


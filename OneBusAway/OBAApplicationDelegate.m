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

#import "OBAApplicationDelegate.h"
@import SystemConfiguration;
@import GoogleAnalytics;
@import OBAKit;
@import SVProgressHUD;
@import Fabric;
@import Crashlytics;
@import PMKCoreLocation;

#import "OBAPushManager.h"
#import "OBAMapDataLoader.h"
#import "OBAStopViewController.h"

#import "OneBusAway-Swift.h"

#import "OBAAnalytics.h"

#import "OBAApplicationUI.h"
#import "OBAClassicApplicationUI.h"
#import "OBACrashlyticsLogger.h"
#import "UIWindow+OBAAdditions.h"

static NSString * const OBALastRegionRefreshDateUserDefaultsKey = @"OBALastRegionRefreshDateUserDefaultsKey";

@interface OBAApplicationDelegate () <OBABackgroundTaskExecutor, OBARegionHelperDelegate, RegionListDelegate, OBAPushManagerDelegate, OnboardingDelegate, PrivacyBrokerDelegate>
@property(nonatomic,strong) UINavigationController *regionNavigationController;
@property(nonatomic,strong) RegionListViewController *regionListViewController;
@property(nonatomic,strong) id<OBAApplicationUI> applicationUI;
@property(nonatomic,strong) OBADeepLinkRouter *deepLinkRouter;
@property(nonatomic,strong) OnboardingViewController *onboardingViewController;
@end

@implementation OBAApplicationDelegate

- (id)init {
    self = [super init];

    if (self) {
        [self registerForNotifications];

        _deepLinkRouter = [self.class setupDeepLinkRouterWithModelDAO:[OBAApplication sharedApplication].modelDao appDelegate:self];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

        OBAApplicationConfiguration *configuration = [[OBAApplicationConfiguration alloc] init];
        configuration.loggers = @[[OBACrashlyticsLogger sharedInstance]];
        [[OBAApplication sharedApplication] startWithConfiguration:configuration];

        [OBAApplication sharedApplication].privacyBroker.delegate = self;
        [OBAApplication sharedApplication].regionHelper.delegate = self;
    }

    return self;
}

- (void)navigateToTarget:(OBANavigationTarget *)navigationTarget {
    [[OBAApplication sharedApplication].references clear];
    [self.applicationUI navigateToTargetInternal:navigationTarget];
}

- (void)_constructUI {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];

    self.applicationUI = [[OBAClassicApplicationUI alloc] init];

    [OBATheme setAppearanceProxies];

    if ([OBAApplicationDelegate awaitingLocationAuthorization]) {
        self.window.rootViewController = self.onboardingViewController;
    }
    else {
        self.window.rootViewController = self.applicationUI.rootViewController;
    }

    [self.window makeKeyAndVisible];
}

#pragma mark - Location Helpers

+ (BOOL)awaitingLocationAuthorization {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined;
}

#pragma mark - UIApplication Methods

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    return [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:handler];
}

- (UIBackgroundTaskIdentifier)endBackgroundTask:(UIBackgroundTaskIdentifier)task {
    [[UIApplication sharedApplication] endBackgroundTask:task];
    return UIBackgroundTaskInvalid;
}

#pragma mark UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeFabric];

    // Register a background handler with the modael service
    [OBAModelService addBackgroundExecutor:self];

    [[OBAPushManager pushManager] startWithLaunchOptions:launchOptions delegate:self APIKey:[OBAApplication sharedApplication].oneSignalAPIKey];

    // Set up Google Analytics. User must be able to opt out of tracking.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:[OBAApplication sharedApplication].googleAnalyticsID];
    BOOL optOut = ![[NSUserDefaults standardUserDefaults] boolForKey:OBAOptInToTrackingDefaultsKey];
    [GAI sharedInstance].optOut = optOut;
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].logger.logLevel = kGAILogLevelWarning;
    [tracker set:[GAIFields customDimensionForIndex:1] value:[OBAApplication sharedApplication].modelDao.currentRegion.regionName];

    [OBAAnalytics configureVoiceOverStatus];

    // On first launch, this refresh process should be deferred.
    if (![OBAApplicationDelegate awaitingLocationAuthorization] && [self hasEnoughTimeElapsedToRefreshRegions]) {
        [[OBAApplication sharedApplication].regionHelper refreshData];
    }

    [self _constructUI];

    return YES;
}

- (BOOL)hasEnoughTimeElapsedToRefreshRegions {
    NSDate *lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:OBALastRegionRefreshDateUserDefaultsKey];

    if (!lastRefresh) {
        return YES;
    }

    NSTimeInterval lastRefreshInterval = [lastRefresh timeIntervalSinceNow];

    // 604,800 seconds in a week. Only refresh once a week.
    return ABS(lastRefreshInterval) > 604800;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    DDLogInfo(@"Application entered background.");

    CLLocation *location = [OBAApplication sharedApplication].locationManager.currentLocation;

    if (location) {
        [OBAApplication sharedApplication].modelDao.mostRecentLocation = location;
    }

    [[OBAApplication sharedApplication].locationManager stopUpdatingLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DDLogInfo(@"Application became active");

    [[OBAApplication sharedApplication].locationManager startUpdatingLocation];
    [[OBAApplication sharedApplication] startReachabilityNotifier];
    [[OBAApplication sharedApplication].regionalAlertsManager update];

    [self.applicationUI applicationDidBecomeActive];

    [GAI sharedInstance].optOut = ![[NSUserDefaults standardUserDefaults] boolForKey:OBAOptInToTrackingDefaultsKey];

    NSString *label = [NSString stringWithFormat:@"API Region: %@", [OBAApplication sharedApplication].modelDao.currentRegion.regionName];

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"configured_region" label:label value:nil];

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"general" label:[NSString stringWithFormat:@"Set Region Automatically: %@", OBAStringFromBool([OBAApplication sharedApplication].modelDao.automaticallySelectRegion)] value:nil];

    if (![OBAApplicationDelegate awaitingLocationAuthorization]) {
        [OBAApplication.sharedApplication.privacyBroker reportUserDataWithNotificationsStatus:[UIApplication sharedApplication].isRegisteredForRemoteNotifications];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[OBAApplication sharedApplication] stopReachabilityNotifier];
}

#pragma mark - Notifications

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidRegionNotification:) name:OBARegionServerInvalidNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentStopsChanged:) name:OBAMostRecentStopsChangedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highPriorityRegionalAlertReceived:) name:RegionalAlertsManager.highPriorityRegionalAlertReceivedNotification object:nil];
}

- (void)invalidRegionNotification:(NSNotification*)note {
    [OBAApplication sharedApplication].modelDao.automaticallySelectRegion = YES;
    [[OBAApplication sharedApplication].regionHelper refreshData];
    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:2] value:OBAStringFromBool(YES)];
}

- (void)recentStopsChanged:(NSNotification*)note {
    [self updateShortcutItemsForRecentStops];
}

- (void)highPriorityRegionalAlertReceived:(NSNotification*)note {
    OBARegionalAlert *alert = note.userInfo[RegionalAlertsManager.highPriorityRegionalAlertUserInfoKey];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alert.title message:alert.summary preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:OBAStrings.readMore style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBANavigationTarget *regionalAlertTarget = [OBANavigationTarget navigationTargetForRegionalAlert:alert];
        [self navigateToTarget:regionalAlertTarget];
    }]];

    [self.topViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Deep Linking

#define kDeepLinkTripPattern @"\\/regions\\/(\\d+).*\\/stops\\/(.*)\\/trips\\/?"

+ (OBADeepLinkRouter*)setupDeepLinkRouterWithModelDAO:(OBAModelDAO*)modelDAO appDelegate:(OBAApplicationDelegate*)appDelegate {
    OBADeepLinkRouter *deepLinkRouter = [[OBADeepLinkRouter alloc] init];

    [deepLinkRouter routePattern:kDeepLinkTripPattern toAction:^(NSArray<NSString *> *matchGroupResults, NSURLComponents *URLComponents) {
        OBAGuard(matchGroupResults.count == 2) else {
            return;
        }

        NSInteger regionIdentifier = [matchGroupResults[0] integerValue];
        NSString *stopID = matchGroupResults[1];
        NSDictionary *queryItems = [NSURLQueryItem oba_dictionaryFromQueryItems:URLComponents.queryItems];

        OBATripDeepLink *tripDeepLink = [[OBATripDeepLink alloc] init];
        tripDeepLink.regionIdentifier = regionIdentifier;
        tripDeepLink.stopID = stopID;
        tripDeepLink.tripID = queryItems[@"trip_id"];
        tripDeepLink.serviceDate = [queryItems[@"service_date"] longLongValue];
        tripDeepLink.stopSequence = [queryItems[@"stop_sequence"] integerValue];

        [SVProgressHUD show];

        [[OBAApplication sharedApplication].modelService requestArrivalAndDepartureWithConvertible:tripDeepLink].then(^(OBAArrivalAndDepartureV2 *arrivalAndDeparture) {
            tripDeepLink.name = arrivalAndDeparture.bestAvailableNameWithHeadsign;

            // OK, it works, so write it into the model DAO.
            [[OBAApplication sharedApplication].modelDao addSharedTrip:tripDeepLink];

            OBANavigationTarget *target = [OBANavigationTarget navigationTarget:OBANavigationTargetTypeRecentStops];
            target.object = tripDeepLink;
            [appDelegate navigateToTarget:target];
        }).catch(^(NSError *error) {
            NSString *body = [NSString stringWithFormat:NSLocalizedString(@"text_error_cant_show_shared_trip_param", @"Error message displayed to the user when something goes wrong with a just-tapped shared trip."), error.localizedDescription];
            [AlertPresenter showWarning:NSLocalizedString(@"msg_something_went_wrong",) body:body];
        }).always(^{
            [SVProgressHUD dismiss];
        });
    }];

    return deepLinkRouter;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    NSInteger regionID = [userActivity.userInfo[OBAHandoff.regionIDKey] integerValue];

    NSURL *URL = userActivity.webpageURL;

    // Use deep link URL above all else
    if (userActivity.userInfo && !URL) {
        // Make sure regions of both clients match
        if ([OBAApplication sharedApplication].modelDao.currentRegion.identifier == regionID) {
            NSString *stopID = userActivity.userInfo[OBAHandoff.stopIDKey];
            OBANavigationTarget *target = [OBANavigationTarget navigationTarget:OBANavigationTargetTypeMap parameters:@{@"stop":@YES, @"stopID":stopID}];
            [self.applicationUI navigateToTargetInternal:target];
            return YES;
        }
        else {
            NSString *title = NSLocalizedString(@"msg_handoff_failure_title", @"Error message title displayed to the user when handoff failed to work.");
            NSString *body = NSLocalizedString(@"msg_handoff_region_mismatch_body", @"Error message body displayed to the user when handoff regions did not match both clients.");

            [AlertPresenter showError:title body:body];
            return NO;
        }
    }

    if (!URL) {
        return NO;
    }

    return [self.deepLinkRouter performActionForURL:URL];
}

/*
 Necessary for onebusaway:// URLs to work.
 */
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    return YES;
}

#pragma mark - Shortcut Items

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {

    [self.applicationUI performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler];
}

- (void)updateShortcutItemsForRecentStops {
    NSMutableArray *dynamicShortcuts = [NSMutableArray array];
    UIApplicationShortcutIcon *clockIcon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeTime];

    for (OBAStopAccessEventV2 *stopEvent in [OBAApplication sharedApplication].modelDao.mostRecentStops) {
        UIApplicationShortcutItem *shortcutItem =
                [[UIApplicationShortcutItem alloc] initWithType:kApplicationShortcutRecents
                                                 localizedTitle:stopEvent.title
                                              localizedSubtitle:nil
                                                           icon:clockIcon
                                                       userInfo:@{ @"stopIds": stopEvent.stopIds }];
        [dynamicShortcuts addObject:shortcutItem];
    }

    [UIApplication sharedApplication].shortcutItems = [dynamicShortcuts oba_pickFirst:4];
}

#pragma mark - Reachability

- (void)reachabilityChanged:(NSNotification*)note {

    OBAReachability *reachability = note.object;

    if (!reachability.isReachable) {
        [AlertPresenter showWarning:NSLocalizedString(@"msg_cannot_connect_to_the_internet", @"Reachability alert title") body:NSLocalizedString(@"msg_check_internet_connection", @"Reachability alert body")];
    }
}

#pragma mark - OBAPushManagerDelegate

- (void)pushManager:(OBAPushManager*)pushManager notificationReceivedWithTitle:(NSString*)title message:(NSString*)message data:(nullable NSDictionary *)data {

    NSDictionary *arrDepData = data[@"arrival_and_departure"];
    OBAAlarm *alarm = [[OBAAlarm alloc] init];

    alarm.regionIdentifier = [arrDepData[@"region_id"] integerValue];
    alarm.stopID = arrDepData[@"stop_id"];
    alarm.tripID = arrDepData[@"trip_id"];
    alarm.serviceDate = [arrDepData[@"service_date"] longLongValue];
    alarm.vehicleID = arrDepData[@"vehicle_id"];
    alarm.stopSequence = [arrDepData[@"stop_sequence"] integerValue];

    [SVProgressHUD show];

    [[OBAApplication sharedApplication].modelService requestArrivalAndDepartureWithConvertible:alarm].then(^(OBAArrivalAndDepartureV2 *arrivalAndDeparture) {
        alarm.title = arrivalAndDeparture.bestAvailableNameWithHeadsign;

        OBANavigationTarget *target = [OBANavigationTarget navigationTarget:OBANavigationTargetTypeRecentStops];
        target.object = alarm;
        [self navigateToTarget:target];
    }).catch(^(NSError *error) {
        NSString *body = [NSString stringWithFormat:NSLocalizedString(@"notifications.error_messages.formatted_cant_display", @"Error message displayed to the user when something goes wrong with a just-tapped notification."), error.localizedDescription];
        [AlertPresenter showWarning:OBAStrings.error body:body];
    }).always(^{
        [SVProgressHUD dismiss];
    });
}

#pragma mark - RegionListDelegate

- (void)regionSelected {
    [self.regionNavigationController removeFromParentViewController];
    self.regionNavigationController = nil;
    self.regionListViewController = nil;

    [self.window oba_setRootViewController:self.applicationUI.rootViewController animated:YES];
}

#pragma mark - OBARegionHelperDelegate

- (RegionListViewController*)regionListViewController {
    if (!_regionListViewController) {
        _regionListViewController = [[RegionListViewController alloc] init];
        _regionListViewController.delegate = self;
    }
    return _regionListViewController;
}

- (UINavigationController*)regionNavigationController {
    if (!_regionNavigationController) {
        _regionNavigationController = [[UINavigationController alloc] initWithRootViewController:self.regionListViewController];
    }

    return _regionNavigationController;
}

- (void)regionHelperShowRegionListController:(OBARegionHelper *)regionHelper {
    [self.window oba_setRootViewController:self.regionNavigationController animated:YES];
}

- (void)regionHelperDidRefreshRegions:(OBARegionHelper*)regionHelper {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:OBALastRegionRefreshDateUserDefaultsKey];
}

#pragma mark - Fabric

- (void)initializeFabric {
    NSMutableArray *fabricKits = [[NSMutableArray alloc] initWithArray:@[Crashlytics.class]];

    if ([OBAAnalytics OKToTrack]) {
        [fabricKits addObject:Answers.class];
    }

    if (fabricKits.count > 0) {
        [Fabric with:fabricKits];
    }
}

#pragma mark - Onboarding

- (UIViewController*)onboardingViewController {
    if (!_onboardingViewController) {
        _onboardingViewController = [[OnboardingViewController alloc] init];
        _onboardingViewController.delegate = self;
    }
    return _onboardingViewController;
}

#pragma mark - PrivacyBrokerDelegate

- (void)addPersonBool:(BOOL)value withKey:(NSString *)withKey {
    //nop
}

- (void)addPersonNumber:(NSNumber *)value withKey:(NSString *)withKey {
    //nop
}

- (void)addPersonString:(NSString *)value withKey:(NSString *)withKey {
    //nop
}

- (void)removePersonKey:(NSString *)key {
    //nop
}

- (void)onboardingControllerRequestedAuthorization:(OnboardingViewController *)onboardingController {

    // behind the scenes, +[CLLocationManager promise] is calling `requestWhenInUseAuthorization`.

    [CLLocationManager promise].then(^(CLLocation *location) {
        return [[OBAApplication sharedApplication].regionHelper refreshData];
    }).catch(^(NSError *error) {
        DDLogError(@"An error occurred while trying to load regions: %@", error);
    }).always(^{
        if ([OBAApplication sharedApplication].modelDao.currentRegion) {
            [self.window oba_setRootViewController:self.applicationUI.rootViewController animated:YES];
        }
        else {
            [self.window oba_setRootViewController:self.regionNavigationController animated:YES];
        }
    });
}

#pragma mark - Private UI Junk

- (UIViewController *)topViewController{
    return [OBAApplicationDelegate topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (UIViewController *)topViewController:(UIViewController *)rootViewController {
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

@end

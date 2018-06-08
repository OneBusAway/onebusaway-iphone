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

#import "OBAPushManager.h"
#import "OBAStopViewController.h"

#import "OneBusAway-Swift.h"

#import "OBAAnalytics.h"

#import "OBAApplicationUI.h"
#import "OBAClassicApplicationUI.h"
#import "OBACrashlyticsLogger.h"
#import "UIWindow+OBAAdditions.h"

static NSString * const OBALastRegionRefreshDateUserDefaultsKey = @"OBALastRegionRefreshDateUserDefaultsKey";

@interface OBAApplicationDelegate () <OBARegionHelperDelegate, RegionListDelegate, OBAPushManagerDelegate, OnboardingDelegate>
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

        _deepLinkRouter = [self setupDeepLinkRouterWithModelDAO:self.application.modelDao appDelegate:self];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

        OBAApplicationConfiguration *configuration = [[OBAApplicationConfiguration alloc] init];
        configuration.loggers = @[[OBACrashlyticsLogger sharedInstance]];
        [self.application startWithConfiguration:configuration];

        self.application.regionHelper.delegate = self;
    }

    return self;
}

- (void)_constructUI {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];


    BOOL showDrawer = [self.application.userDefaults boolForKey:OBAExperimentalUseDrawerUIDefaultsKey];

    if (showDrawer) {
        self.applicationUI = [[DrawerApplicationUI alloc] initWithApplication:self.application];
    }
    else {
        self.applicationUI = [[OBAClassicApplicationUI alloc] initWithApplication:self.application];
    }

    [OBATheme setAppearanceProxies];

    if (OBALocationManager.awaitingLocationAuthorization) {
        self.window.rootViewController = self.onboardingViewController;
    }
    else {
        self.window.rootViewController = self.applicationUI.rootViewController;
    }

    [self.window makeKeyAndVisible];
}

#pragma mark - UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeFabric];

#ifndef TARGET_IPHONE_SIMULATOR
    [[OBAPushManager pushManager] startWithLaunchOptions:launchOptions delegate:self APIKey:self.application.oneSignalAPIKey];
#endif
    
    // Set up Google Analytics. User must be able to opt out of tracking.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:self.application.googleAnalyticsID];
    BOOL optOut = ![OBAApplication.sharedApplication.userDefaults boolForKey:OBAOptInToTrackingDefaultsKey];
    [GAI sharedInstance].optOut = optOut;
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].logger.logLevel = kGAILogLevelWarning;
    [tracker set:[GAIFields customDimensionForIndex:1] value:self.application.modelDao.currentRegion.regionName];

    [OBAAnalytics configureVoiceOverStatus];

    // On first launch, this refresh process should be deferred.
    if (!OBALocationManager.awaitingLocationAuthorization && [self hasEnoughTimeElapsedToRefreshRegions]) {
        [self.application.regionHelper refreshData];
    }

    [self _constructUI];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    DDLogInfo(@"Application entered background.");

    CLLocation *location = self.application.locationManager.currentLocation;

    if (location) {
        self.application.modelDao.mostRecentLocation = location;
    }

    [self.application applicationDidEnterBackground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DDLogInfo(@"Application became active");

    [self.application.locationManager startUpdatingLocation];
    [self.application startReachabilityNotifier];
    [self.application.regionalAlertsManager update];

    [self.applicationUI applicationDidBecomeActive];

    [GAI sharedInstance].optOut = ![OBAApplication.sharedApplication.userDefaults boolForKey:OBAOptInToTrackingDefaultsKey];

    NSString *label = [NSString stringWithFormat:@"API Region: %@", self.application.modelDao.currentRegion.regionName];

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"configured_region" label:label value:nil];

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"general" label:[NSString stringWithFormat:@"Set Region Automatically: %@", OBAStringFromBool(self.application.modelDao.automaticallySelectRegion)] value:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self.application stopReachabilityNotifier];
}

#pragma mark - Properties

+ (OBAApplication*)application {
    return [OBAApplication sharedApplication];
}

- (OBAApplication*)application {
    return [OBAApplication sharedApplication];
}

#pragma mark - Notification Center

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidRegionNotification:) name:OBARegionServerInvalidNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentStopsChanged:) name:OBAMostRecentStopsChangedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highPriorityRegionalAlertReceived:) name:OBARegionalAlertsManager.highPriorityRegionalAlertReceivedNotification object:nil];
}

- (void)invalidRegionNotification:(NSNotification*)note {
    self.application.modelDao.automaticallySelectRegion = YES;
    [self.application.regionHelper refreshData];
    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:2] value:OBAStringFromBool(YES)];
}

- (void)recentStopsChanged:(NSNotification*)note {
    [self updateShortcutItemsForRecentStops];
}

- (void)highPriorityRegionalAlertReceived:(NSNotification*)note {
    OBARegionalAlert *alert = note.userInfo[OBARegionalAlertsManager.highPriorityRegionalAlertUserInfoKey];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alert.title message:alert.summary preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:OBAStrings.readMore style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBANavigationTarget *regionalAlertTarget = [OBANavigationTarget navigationTargetForRegionalAlert:alert];
        [self navigateToTarget:regionalAlertTarget];
    }]];

    [self.topViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - OBANavigator

- (void)navigateToTarget:(OBANavigationTarget *)navigationTarget {
    [self.application.references clear];
    [self.applicationUI navigateToTargetInternal:navigationTarget];
}

- (id<OBANavigator>)navigator {
    return self;
}

#pragma mark - Deep Linking

- (void)routeDeepLinkStop:(NSURLComponents *)URLComponents appDelegate:(OBAApplicationDelegate *)appDelegate matchGroupResults:(NSArray<NSString *> *)matchGroupResults {
    OBAGuard(matchGroupResults.count == 2) else {
        return;
    }

    NSInteger regionIdentifier = [matchGroupResults[0] integerValue];
    NSString *stopID = matchGroupResults[1];

    if (self.application.modelDao.currentRegion.identifier != regionIdentifier) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"deep_links.errors.region_mismatch_alert.title", @"Title of an alert displayed when the user is trying to view an object from a different region than the one they're currently in.") message:NSLocalizedString(@"deep_links.errors.region_mismatch_alert.message", @"Message of an alert displayed when the user is trying to view an object from a different region than the one they're currently in.") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"deep_links.errors.region_mismatch_alert.change_regions_button", @"The button title is Change Regions and this is used to switch the user to the correct region.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([self.application.regionHelper selectRegionWithIdentifier:regionIdentifier]) {
                OBANavigationTarget *navTarget = [OBANavigationTarget navigationTargetForStopID:stopID];
                [appDelegate navigateToTarget:navTarget];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"deep_links.errors.region_mismatch_alert.do_nothing_button", @"The button title is Do Nothing and this is used to, ahem, do nothing.") style:UIAlertActionStyleDefault handler:nil]];

        [appDelegate.topViewController presentViewController:alert animated:YES completion:nil];

        return;
    }

    OBANavigationTarget *navTarget = [OBANavigationTarget navigationTargetForStopID:stopID];
    [appDelegate navigateToTarget:navTarget];
}

- (void)routeDeepLinkTrip:(NSURLComponents *)URLComponents appDelegate:(OBAApplicationDelegate *)appDelegate matchGroupResults:(NSArray<NSString *> *)matchGroupResults {
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

    [self.application.modelService requestArrivalAndDepartureWithConvertible:tripDeepLink].then(^(OBAArrivalAndDepartureV2 *arrivalAndDeparture) {
        tripDeepLink.name = arrivalAndDeparture.bestAvailableNameWithHeadsign;

        // OK, it works, so write it into the model DAO.
        [self.application.modelDao addSharedTrip:tripDeepLink];

        OBADeepLinkNavigationTarget *target = [OBADeepLinkNavigationTarget targetWithTripDeepLink:tripDeepLink];
        [appDelegate navigateToTarget:target];
    }).catch(^(NSError *error) {
        NSString *body = [NSString stringWithFormat:NSLocalizedString(@"text_error_cant_show_shared_trip_param", @"Error message displayed to the user when something goes wrong with a just-tapped shared trip."), error.localizedDescription];
        [AlertPresenter showWarning:NSLocalizedString(@"msg_something_went_wrong",) body:body];
    }).always(^{
        [SVProgressHUD dismiss];
    });
}

- (OBADeepLinkRouter*)setupDeepLinkRouterWithModelDAO:(OBAModelDAO*)modelDAO appDelegate:(OBAApplicationDelegate*)appDelegate {
    OBADeepLinkRouter *deepLinkRouter = [[OBADeepLinkRouter alloc] initWithDeepLinkBaseURL:[NSURL URLWithString:OBADeepLinkServerAddress]];

    [deepLinkRouter routePattern:OBADeepLinkTripRegexPattern toAction:^(NSArray<NSString *> *matchGroupResults, NSURLComponents *URLComponents) {
        [self routeDeepLinkTrip:URLComponents appDelegate:appDelegate matchGroupResults:matchGroupResults];
    }];

    [deepLinkRouter routePattern:OBADeepLinkStopRegexPattern toAction:^(NSArray<NSString *> *matchGroupResults, NSURLComponents *URLComponents) {
        [self routeDeepLinkStop:URLComponents appDelegate:appDelegate matchGroupResults:matchGroupResults];
    }];

    return deepLinkRouter;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    NSInteger regionID = [userActivity.userInfo[OBAHandoff.regionIDKey] integerValue];

    NSURL *URL = userActivity.webpageURL;

    // Use deep link URL above all else
    if (userActivity.userInfo && !URL) {
        // Make sure regions of both clients match
        if (self.application.modelDao.currentRegion.identifier == regionID) {
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

    for (OBAStopAccessEventV2 *stopEvent in self.application.modelDao.mostRecentStops) {
        UIApplicationShortcutItem *shortcutItem =
                [[UIApplicationShortcutItem alloc] initWithType:kApplicationShortcutRecents
                                                 localizedTitle:stopEvent.title
                                              localizedSubtitle:nil
                                                           icon:clockIcon
                                                       userInfo:@{ @"stopID": stopEvent.stopID }];
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

    [self.application.modelService requestArrivalAndDepartureWithConvertible:alarm].then(^(OBAArrivalAndDepartureV2 *arrivalAndDeparture) {
        alarm.title = arrivalAndDeparture.bestAvailableNameWithHeadsign;
        OBAAlarmNavigationTarget *alarmTarget = [OBAAlarmNavigationTarget navigationTargetWithAlarm:alarm];
        [self navigateToTarget:alarmTarget];
    }).catch(^(NSError *error) {
        NSString *body = [NSString stringWithFormat:NSLocalizedString(@"notifications.error_messages.formatted_cant_display", @"Error message displayed to the user when something goes wrong with a just-tapped notification."), error.localizedDescription];
        [AlertPresenter showWarning:OBAStrings.error body:body];
    }).always(^{
        [SVProgressHUD dismiss];
    });
}

#pragma mark - Regions

- (void)regionSelected {
    [self.regionNavigationController removeFromParentViewController];
    self.regionNavigationController = nil;
    self.regionListViewController = nil;

    [self.window oba_setRootViewController:self.applicationUI.rootViewController animated:YES];
}

- (BOOL)hasEnoughTimeElapsedToRefreshRegions {
    NSDate *lastRefresh = [OBAApplication.sharedApplication.userDefaults objectForKey:OBALastRegionRefreshDateUserDefaultsKey];

    if (!lastRefresh) {
        return YES;
    }

    NSTimeInterval lastRefreshInterval = [lastRefresh timeIntervalSinceNow];

    // 604,800 seconds in a week. Only refresh once a week.
    return ABS(lastRefreshInterval) > 604800;
}

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
    [self.application.userDefaults setObject:[NSDate date] forKey:OBALastRegionRefreshDateUserDefaultsKey];
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

- (void)onboardingControllerRequestedAuthorization:(OnboardingViewController *)onboardingController {

    // behind the scenes, +[CLLocationManager promise] is calling `requestWhenInUseAuthorization`.

    [CLLocationManager promise].then(^(CLLocation *location) {
        return [self.application.regionHelper refreshData];
    }).catch(^(NSError *error) {
        DDLogError(@"An error occurred while trying to load regions: %@", error);
    }).always(^{
        if (self.application.modelDao.currentRegion) {
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

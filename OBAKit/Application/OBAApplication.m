//
//  OBAApplication.m
//  OneBusAwaySDK
//
//  Created by Dima Belov on 4/25/15.
//  Copyright (c) 2015 One Bus Away. All rights reserved.
//

#import <OBAKit/OBAApplication.h>
#import <OBAKit/OBAUser.h>
#import <OBAKit/OBAModelDAOUserPreferencesImpl.h>
#import <OBAKit/OBALogging.h>
#import <OBAKit/OBAApplicationConfiguration.h>
#import <OBAKit/OBACommon.h>
#import <OBAKit/OBAKit-Swift.h>

static NSString * const kAppGroup = @"group.org.onebusaway.iphone";
static NSString *const kOBADefaultRegionApiServerName = @"http://regions.onebusaway.org";
NSString *const OBARegionServerInvalidNotification = @"OBARegionServerInvalidNotification";
NSString * const OBAHasMigratedDefaultsToAppGroupDefaultsKey = @"OBAHasMigratedDefaultsToAppGroupDefaultsKey";

@interface OBAApplication ()
@property (nonatomic, strong, readwrite) OBAApplicationConfiguration *configuration;
@property (nonatomic, strong, readwrite) OBAReferencesV2 *references;
@property (nonatomic, strong, readwrite) OBAModelDAO *modelDao;
@property (nonatomic, strong, readwrite) PromisedModelService *modelService;
@property (nonatomic, strong, readwrite) OBALocationManager *locationManager;
@property (nonatomic, strong, readwrite) OBAReachability *reachability;
@property (nonatomic, strong, readwrite) OBARegionHelper *regionHelper;
@property (nonatomic, strong, readwrite) RegionalAlertsManager *regionalAlertsManager;
@property (nonatomic, strong, readwrite) OBALogging *loggingManager;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@end

@implementation OBAApplication
@dynamic isServerReachable;
@dynamic consoleLogger;

+ (instancetype)sharedApplication {
    static OBAApplication *oba;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        oba = [[OBAApplication alloc] init];
    });

    return oba;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regionUpdated:) name:OBARegionDidUpdateNotification object:nil];
    }
    return self;
}

- (void)startWithConfiguration:(OBAApplicationConfiguration *)configuration {
    self.configuration = configuration;
    self.loggingManager = [[OBALogging alloc] initWithLoggers:configuration.loggers];

    if (![NSUserDefaults.standardUserDefaults boolForKey:OBAHasMigratedDefaultsToAppGroupDefaultsKey]) {
        [self migrateUserDefaultsToSuite];
    }

    [self registerAppDefaults];

    self.references = [[OBAReferencesV2 alloc] init];

    id<OBAModelPersistenceLayer> persistence = [[OBAModelDAOUserPreferencesImpl alloc] init];
    self.modelDao = [[OBAModelDAO alloc] initWithModelPersistenceLayer:persistence];
    self.locationManager = [[OBALocationManager alloc] initWithModelDAO:self.modelDao];

    self.modelService = [[PromisedModelService alloc] init];
    self.modelService.references = self.references;
    self.modelService.modelDao = self.modelDao;

    OBAModelFactory *modelFactory = [[OBAModelFactory alloc] initWithReferences:self.references];
    self.modelService.modelFactory = modelFactory;

    self.modelService.locationManager = self.locationManager;

    self.regionHelper = [[OBARegionHelper alloc] initWithLocationManager:self.locationManager modelService:self.modelService];

    if (!self.configuration.extensionMode) {
        self.regionalAlertsManager = [[RegionalAlertsManager alloc] init];
        self.regionalAlertsManager.region = self.modelDao.currentRegion;
    }

    [self refreshSettings];
}

#pragma mark - Defaults

- (NSUserDefaults*)userDefaults {
    if (!_userDefaults) {
        _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroup];
    }

    return _userDefaults;
}

- (void)registerAppDefaults {
    NSMutableDictionary *defaults = [[NSMutableDictionary alloc] init];

    defaults[OBAShareRegionPIIUserDefaultsKey] = @(YES);
    defaults[OBAShareLocationPIIUserDefaultsKey] = @(YES);
    defaults[OBAShareLogsPIIUserDefaultsKey] = @(YES);
    defaults[OBASetRegionAutomaticallyKey] = @(YES);
    defaults[kUngroupedBookmarksOpenKey] = @(YES);
    defaults[OBAOptInToCrashReportingDefaultsKey] = @(YES);
    defaults[OBAOptInToTrackingDefaultsKey] = @(YES);
    defaults[OBADisplayUserHeadingOnMapDefaultsKey] = @(YES);
    defaults[OBAMapSelectedTypeDefaultsKey] = @(MKMapTypeStandard);

    [self.userDefaults registerDefaults:defaults];
}

- (void)migrateUserDefaultsToSuite {
    NSDictionary<NSString *, id> *oldDefaults = NSUserDefaults.standardUserDefaults.dictionaryRepresentation;

    for (NSString *key in oldDefaults) {
        id object = oldDefaults[key];
        [self.userDefaults setObject:object forKey:key];
    }

    [NSUserDefaults.standardUserDefaults setBool:YES forKey:OBAHasMigratedDefaultsToAppGroupDefaultsKey];
}

#pragma mark - App Lifecycle Events

- (void)applicationDidEnterBackground {
    [self.locationManager stopUpdatingLocation];

    [self.modelService.obaJsonDataSource cancelOpenConnections];
    [self.modelService.googleMapsJsonDataSource cancelOpenConnections];
    [self.modelService.obaRegionJsonDataSource cancelOpenConnections];
    [self.modelService.obacoJsonDataSource cancelOpenConnections];
}

#pragma mark - Reachability

- (void)startReachabilityNotifier {
    [self.reachability startNotifier];
}

- (void)stopReachabilityNotifier {
    [self.reachability stopNotifier];
}

- (BOOL)isServerReachable {
    return self.reachability.isReachable;
}

- (OBAReachability*)reachability {
    if (!_reachability) {
        _reachability = [OBAReachability reachabilityForInternetConnection];
    }
    return _reachability;
}

#pragma mark - Region

- (void)regionUpdated:(NSNotification*)note {
    self.regionalAlertsManager.region = self.modelDao.currentRegion;
    [self refreshSettings];
}

#pragma mark - Bundle Settings

- (NSString*)formattedAppVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString*)formattedAppBuild {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString*)fullAppVersionString {
    return [NSString stringWithFormat:@"%@ (%@)", [self formattedAppVersion], [self formattedAppBuild]];
}

#pragma mark - App Keys

- (NSString*)googleAnalyticsID {
    return @"UA-2423527-17";
}

- (NSString*)oneSignalAPIKey {
    return @"d5d0d28a-6091-46cd-9627-0ce01ffa9f9e";
}

- (NSString*)appStoreAppID {
    return @"329380089";
}

#pragma mark - App/Region/API State

- (void)refreshSettings {
    if (self.modelDao.currentRegion.baseURL) {
        self.modelService.obaJsonDataSource = [OBAJsonDataSource JSONDataSourceWithBaseURL:self.modelDao.currentRegion.baseURL userID:[OBAUser userIdFromDefaults]];
    }

    self.modelService.googleMapsJsonDataSource = [OBAJsonDataSource googleMapsJSONDataSource];
    self.modelService.obaRegionJsonDataSource = [OBAJsonDataSource JSONDataSourceWithBaseURL:[NSURL URLWithString:kOBADefaultRegionApiServerName] userID:[OBAUser userIdFromDefaults]];
    self.modelService.obacoJsonDataSource = [OBAJsonDataSource obacoJSONDataSource];

    if (!self.configuration.extensionMode) {
        [self.regionalAlertsManager update];
    }
}

#pragma mark - Logging

- (NSArray<NSData*>*)logFileData {
    return self.loggingManager.logFileData;
}

- (OBAConsoleLogger*)consoleLogger {
    return self.loggingManager.consoleLogger;
}

@end

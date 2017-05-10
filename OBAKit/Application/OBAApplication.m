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
#import <OBAKit/OBAKit-Swift.h>
#import <OBAKit/OBACommon.h>

static NSString *const kOBADefaultRegionApiServerName = @"http://regions.onebusaway.org";
NSString *const OBARegionServerInvalidNotification = @"OBARegionServerInvalidNotification";

@interface OBAApplication ()
@property (nonatomic, strong, readwrite) OBAReferencesV2 *references;
@property (nonatomic, strong, readwrite) OBAModelDAO *modelDao;
@property (nonatomic, strong, readwrite) OBAModelService *modelService;
@property (nonatomic, strong, readwrite) OBALocationManager *locationManager;
@property (nonatomic, strong, readwrite) OBAReachability *reachability;
@property (nonatomic, strong, readwrite) OBARegionHelper *regionHelper;
@property (nonatomic, strong, readwrite) RegionalAlertsManager *regionalAlertsManager;
@property (nonatomic, strong, readwrite) PrivacyBroker *privacyBroker;
@property (nonatomic, strong, readwrite) OBALogging *loggingManager;
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
    self.loggingManager = [[OBALogging alloc] initWithLoggers:configuration.loggers];

    self.references = [[OBAReferencesV2 alloc] init];

    id<OBAModelPersistenceLayer> persistence = [[OBAModelDAOUserPreferencesImpl alloc] init];
    self.modelDao = [[OBAModelDAO alloc] initWithModelPersistenceLayer:persistence];
    self.locationManager = [[OBALocationManager alloc] initWithModelDAO:self.modelDao];

    self.modelService = [[OBAModelService alloc] init];
    self.modelService.references = self.references;
    self.modelService.modelDao = self.modelDao;

    OBAModelFactory *modelFactory = [[OBAModelFactory alloc] initWithReferences:self.references];
    self.modelService.modelFactory = modelFactory;

    self.modelService.locationManager = self.locationManager;

    self.regionHelper = [[OBARegionHelper alloc] initWithLocationManager:self.locationManager modelService:self.modelService];

    self.privacyBroker = [[PrivacyBroker alloc] initWithModelDAO:self.modelDao locationManager:self.locationManager];

    self.regionalAlertsManager = [[RegionalAlertsManager alloc] init];
    self.regionalAlertsManager.region = self.modelDao.currentRegion;

    [self registerAppDefaults];

    [self refreshSettings];
}

#pragma mark - Defaults

- (void)registerAppDefaults {
    NSMutableDictionary *defaults = [[NSMutableDictionary alloc] init];

    defaults[OBAShareRegionPIIUserDefaultsKey] = @(YES);
    defaults[OBAShareLocationPIIUserDefaultsKey] = @(YES);
    defaults[OBAShareLogsPIIUserDefaultsKey] = @(YES);
    defaults[OBASetRegionAutomaticallyKey] = @(YES);
    defaults[kUngroupedBookmarksOpenKey] = @(YES);
    defaults[OBAOptInToCrashReportingDefaultsKey] = @(YES);
    defaults[OBAOptInToTrackingDefaultsKey] = @(YES);
    defaults[OBAAllowReviewPromptsDefaultsKey] = @(YES);
    defaults[OBAMapSelectedTypeDefaultsKey] = @(MKMapTypeStandard);

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
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

- (NSString*)apptentiveAPIKey {
    return @"3363af9a6661c98dec30fedea451a06dd7d7bc9f70ef38378a9d5a15ac7d4926";
}

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

    [self.regionalAlertsManager update];
}

#pragma mark - Logging

- (NSArray<NSData*>*)logFileData {
    return self.loggingManager.logFileData;
}

- (OBAConsoleLogger*)consoleLogger {
    return self.loggingManager.consoleLogger;
}

@end

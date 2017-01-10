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
#import <OBAKit/OBAKit-Swift.h>
#import <OBAKit/OBACommon.h>

static NSString *const kOBADefaultRegionApiServerName = @"http://regions.onebusaway.org";
NSString *const kOBAApplicationSettingsRegionRefreshNotification = @"kOBAApplicationSettingsRegionRefreshNotification";

@interface OBAApplication ()
@property (nonatomic, strong, readwrite) OBAReferencesV2 *references;
@property (nonatomic, strong, readwrite) OBAModelDAO *modelDao;
@property (nonatomic, strong, readwrite) OBAModelService *modelService;
@property (nonatomic, strong, readwrite) OBALocationManager *locationManager;
@property (nonatomic, strong, readwrite) OBAReachability *reachability;
@property (nonatomic, strong, readwrite) OBARegionHelper *regionHelper;
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
        _loggingManager = [[OBALogging alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regionUpdated:) name:OBARegionDidUpdateNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBARegionDidUpdateNotification object:nil];
}

- (void)start {
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

    self.regionHelper = [[OBARegionHelper alloc] initWithLocationManager:self.locationManager];

    self.privacyBroker = [[PrivacyBroker alloc] initWithModelDAO:self.modelDao locationManager:self.locationManager];

    [self registerAppDefaults];

    [self refreshSettings];
}

#pragma mark - Defaults

- (void)registerAppDefaults {
    NSMutableDictionary *defaults = [[NSMutableDictionary alloc] init];

    defaults[OBAShareRegionPIIUserDefaultsKey] = @(YES);
    defaults[OBAShareLocationPIIUserDefaultsKey] = @(YES);
    defaults[OBAShareLogsPIIUserDefaultsKey] = @(YES);
    defaults[kSetRegionAutomaticallyKey] = @(YES);
    defaults[kUngroupedBookmarksOpenKey] = @(YES);
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

#pragma mark - App/Region/API State

- (void)refreshSettings {    
    if (self.modelDao.currentRegion.baseURL) {
        self.modelService.obaJsonDataSource = [OBAJsonDataSource JSONDataSourceWithBaseURL:self.modelDao.currentRegion.baseURL userID:[OBAUser userIdFromDefaults]];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOBAApplicationSettingsRegionRefreshNotification object:nil];
    }

    self.modelService.googleMapsJsonDataSource = [OBAJsonDataSource googleMapsJSONDataSource];
    self.modelService.obaRegionJsonDataSource = [OBAJsonDataSource JSONDataSourceWithBaseURL:[NSURL URLWithString:kOBADefaultRegionApiServerName] userID:[OBAUser userIdFromDefaults]];
}

#pragma mark - Logging

- (NSArray<NSData*>*)logFileData {
    return self.loggingManager.logFileData;
}

- (OBAConsoleLogger*)consoleLogger {
    return self.loggingManager.consoleLogger;
}

@end

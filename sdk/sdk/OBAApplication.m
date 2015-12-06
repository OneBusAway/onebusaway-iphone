//
//  OBAApplication.m
//  OneBusAwaySDK
//
//  Created by Dima Belov on 4/25/15.
//  Copyright (c) 2015 One Bus Away. All rights reserved.
//

#import "OBAApplication.h"

static NSString *const kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";
static NSString *const kOBADefaultRegionApiServerName = @"regions.onebusaway.org";

NSString *const kOBAApplicationSettingsRegionRefreshNotification = @"kOBAApplicationSettingsRegionRefreshNotification";

@interface OBAApplication ()

@property (nonatomic, strong, readwrite) OBAReferencesV2 *references;
@property (nonatomic, strong, readwrite) OBAModelDAO *modelDao;
@property (nonatomic, strong, readwrite) OBAModelService *modelService;
@property (nonatomic, strong, readwrite) OBALocationManager *locationManager;

@end

@implementation OBAApplication

+ (instancetype)sharedApplication {
    static OBAApplication *oba;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        oba = [[OBAApplication alloc] init];
    });

    return oba;
}

- (void)start {
    self.references = [[OBAReferencesV2 alloc] init];
    self.modelDao = [[OBAModelDAO alloc] init];
    self.locationManager = [[OBALocationManager alloc] initWithModelDao:self.modelDao];

    self.modelService = [[OBAModelService alloc] init];
    self.modelService.references = self.references;
    self.modelService.modelDao = self.modelDao;

    OBAModelFactory *modelFactory = [[OBAModelFactory alloc] initWithReferences:self.references];
    self.modelService.modelFactory = modelFactory;

    self.modelService.locationManager = self.locationManager;

    [self refreshSettings];
}

#pragma mark - OS Settings

- (BOOL)useHighContrastUI {
    return UIAccessibilityDarkerSystemColorsEnabled() || UIAccessibilityIsReduceTransparencyEnabled();
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

#pragma mark - Crazy App State Refresh Thing

- (void)refreshSettings {
    NSString *apiServerName = [self.modelDao normalizedAPIServerURL];
    
    if (!apiServerName) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOBAApplicationSettingsRegionRefreshNotification object:nil];
    }

    NSString *userId = [self userIdFromDefaults:[NSUserDefaults standardUserDefaults]];
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *obaArgs = [NSString stringWithFormat:@"key=org.onebusaway.iphone&app_uid=%@&app_ver=%@", userId, appVersion];

    OBADataSourceConfig *obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:apiServerName args:obaArgs];
    OBAJsonDataSource *obaJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:obaDataSourceConfig];
    _modelService.obaJsonDataSource = obaJsonDataSource;

    OBADataSourceConfig *googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"https://maps.googleapis.com" args:@"&sensor=true"];
    OBAJsonDataSource *googleMapsJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:googleMapsDataSourceConfig];
    _modelService.googleMapsJsonDataSource = googleMapsJsonDataSource;

    NSString *regionApiServerName = [[NSUserDefaults standardUserDefaults] objectForKey:@"oba_region_api_server"];

    if (regionApiServerName.length == 0) {
        regionApiServerName = kOBADefaultRegionApiServerName;
    }

    regionApiServerName = [NSString stringWithFormat:@"http://%@", regionApiServerName];

    OBADataSourceConfig *obaRegionDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:regionApiServerName args:obaArgs];
    OBAJsonDataSource *obaRegionJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:obaRegionDataSourceConfig];
    _modelService.obaRegionJsonDataSource = obaRegionJsonDataSource;

    [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"oba_application_version"];
}

- (NSString *)userIdFromDefaults:(NSUserDefaults *)userDefaults {
    NSString *userId = [userDefaults stringForKey:kOBAHiddenPreferenceUserId];

    if (!userId) {
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

@end

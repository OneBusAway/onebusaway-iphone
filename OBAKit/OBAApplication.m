//
//  OBAApplication.m
//  OneBusAwaySDK
//
//  Created by Dima Belov on 4/25/15.
//  Copyright (c) 2015 One Bus Away. All rights reserved.
//

#import "OBAApplication.h"
#import "OBAUser.h"
#import "OBAModelDAOUserPreferencesImpl.h"

static NSString *const kOBADefaultRegionApiServerName = @"http://regions.onebusaway.org";
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

    id<OBAModelPersistenceLayer> persistence = [[OBAModelDAOUserPreferencesImpl alloc] init];
    self.modelDao = [[OBAModelDAO alloc] initWithModelPersistenceLayer:persistence];
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

    self.modelService.obaJsonDataSource = [OBAJsonDataSource JSONDataSourceWithBaseURL:[NSURL URLWithString:apiServerName] userID:[OBAUser userIdFromDefaults]];
    self.modelService.googleMapsJsonDataSource = [OBAJsonDataSource googleMapsJSONDataSource];
    self.modelService.obaRegionJsonDataSource = [OBAJsonDataSource JSONDataSourceWithBaseURL:[NSURL URLWithString:kOBADefaultRegionApiServerName] userID:[OBAUser userIdFromDefaults]];
}

@end

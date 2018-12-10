/**
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

#import "OBAAnalytics.h"
@import OBAKit;
@import GoogleAnalytics;

// New Firebase Analytics Events
NSString * const OBAAnalyticsEventTripProblemReported = @"tripProblemReported";
NSString * const OBAAnalyticsStartupScreen = @"startupScreen";
NSString * const OBAAnalyticsSearchPerformed = @"searchPerformed";
NSString * const OBAAnalyticsServiceAlertTapped = @"serviceAlertTapped";
NSString * const OBAAnalyticsEventInfoRowTapped = @"infoRowTapped";

// Old Google Analytics Categories
NSString * const OBAAnalyticsCategoryAppSettings = @"app_settings";
NSString * const OBAAnalyticsCategoryUIAction = @"ui_action";
NSString * const OBAAnalyticsCategoryAccessibility = @"accessibility";
NSString * const OBAAnalyticsCategorySubmit = @"submit";

NSString * const OBAAnalyticsDimensionOn = @"ON";
NSString * const OBAAnalyticsDimensionOff = @"OFF";

NSInteger const OBAAnalyticsDimensionVoiceOver = 4;

@interface OBAAnalytics ()
@property(nonatomic,strong) OBAApplication *application;
@end

@implementation OBAAnalytics
@dynamic OKToTrack;

+ (instancetype)sharedInstance {
    static OBAAnalytics *analytics = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        analytics = [[OBAAnalytics alloc] initWithApplication:OBAApplication.sharedApplication];
    });
    return analytics;
}

- (instancetype)initWithApplication:(OBAApplication*)application {
    self = [super init];

    if (self) {
        _application = application;

        [self configureGoogleAnalytics];
        [self configureFirebaseAnalytics];
        [self updateOptOutState];
    }
    return self;
}

- (void)configureGoogleAnalytics {
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:self.application.googleAnalyticsID];
    [GAI sharedInstance].logger.logLevel = kGAILogLevelWarning;
    [tracker set:kGAISampleRate value:@"1.0"];
    [tracker set:[GAIFields customDimensionForIndex:1] value:self.application.modelDao.currentRegion.regionName];
}

- (void)configureFirebaseAnalytics {
    if (![NSFileManager.defaultManager fileExistsAtPath:self.application.firebaseAnalyticsConfigFilePath]) {
        NSLog(@"Firebase analytics config file does not exist. Please add it to the bundle to enable Firebase support.");
        return;
    }

    FIROptions *options = [[FIROptions alloc] initWithContentsOfFile:self.application.firebaseAnalyticsConfigFilePath];
    [FIRApp configureWithOptions:options];

    if (self.application.modelDao.currentRegion) {
        [FIRAnalytics setUserPropertyString:self.application.modelDao.currentRegion.regionName forName:@"RegionName"];
    }
}

- (void)updateOptOutState {
    [GAI sharedInstance].optOut = !self.OKToTrack;
    [FIRAnalyticsConfiguration.sharedInstance setAnalyticsCollectionEnabled:self.OKToTrack];
}

- (BOOL)OKToTrack {
    return [self.application.userDefaults boolForKey:OBAOptInToTrackingDefaultsKey];
}

- (void)configureVoiceOverStatus {
    NSString *value = UIAccessibilityIsVoiceOverRunning() ? OBAAnalyticsDimensionOn : OBAAnalyticsDimensionOff;
    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:OBAAnalyticsDimensionVoiceOver] value:value];

    [FIRAnalytics setUserPropertyString:value forName:@"UsesVoiceOver"];
}

- (void)setReportedFontSize:(CGFloat)fontSize {
    [FIRAnalytics setUserPropertyString:[NSString stringWithFormat:@"%.0f", fontSize] forName:@"FontSize"];
}

- (void)setUsesHighConstrast:(BOOL)usesHighContrast {
    [FIRAnalytics setUserPropertyString:usesHighContrast ? OBAAnalyticsDimensionOn : OBAAnalyticsDimensionOff forName:@"UsesHighContrastUI"];
}

- (void)reportEventWithCategory:(NSString *)category action:(NSString*)action label:(NSString*)label value:(id)value {
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:value] build]];
}

- (void)reportScreenView:(NSString *)label {
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:label];
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createScreenView] build]];

    // FIRAnalytics does this automatically.
}

- (void)reportViewController:(UIViewController*)viewController {
    [self reportScreenView:[NSString stringWithFormat:@"View: %@", viewController.class]];

    // FIRAnalytics does this automatically.
}

@end

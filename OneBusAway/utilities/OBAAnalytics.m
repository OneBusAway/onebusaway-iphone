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

NSString * const OBAAnalyticsCategoryAppSettings = @"app_settings";
NSString * const OBAAnalyticsCategoryUIAction = @"ui_action";
NSString * const OBAAnalyticsCategoryAccessibility = @"accessibility";
NSString * const OBAAnalyticsCategorySubmit = @"submit";

NSString * const OBAAnalyticsDimensionOn = @"ON";
NSString * const OBAAnalyticsDimensionOff = @"OFF";

NSInteger const OBAAnalyticsDimensionVoiceOver = 4;

@implementation OBAAnalytics

+ (BOOL)OKToTrack {
    return [OBAApplication.sharedApplication.userDefaults boolForKey:OBAOptInToTrackingDefaultsKey];
}

+ (void)configureVoiceOverStatus {
    if (UIAccessibilityIsVoiceOverRunning()) {
        [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:OBAAnalyticsDimensionVoiceOver] value:OBAAnalyticsDimensionOn];
    } else {
        [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:OBAAnalyticsDimensionVoiceOver] value:OBAAnalyticsDimensionOff];
    }
}

+ (void)reportEventWithCategory:(NSString *)category action:(NSString*)action label:(NSString*)label value:(id)value {
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:value] build]];
}

+ (void)reportScreenView:(NSString *)label {
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:label];
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

+ (void)reportViewController:(UIViewController*)viewController {
    [self reportScreenView:[NSString stringWithFormat:@"View: %@", viewController.class]];
}

@end

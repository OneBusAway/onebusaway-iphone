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

@import UIKit;
@import GoogleAnalytics;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBAAnalyticsCategoryAppSettings;
extern NSString * const OBAAnalyticsCategoryUIAction;
extern NSString * const OBAAnalyticsCategoryAccessibility;
extern NSString * const OBAAnalyticsCategorySubmit;

@interface OBAAnalytics : NSObject
+ (void)configureVoiceOverStatus;
+ (void)reportEventWithCategory:(NSString *)category action:(NSString*)action label:(NSString*)label value:(nullable id)value;
+ (void)reportScreenView:(NSString *)label;

// This is automatically called for every view controller whose class name is prefixed with "OBA"
// e.g. OBAStopViewController, but not UINavigationController.
// This is accomplished through method swizzling. See UIViewController+OBAAnalytics.
+ (void)reportViewController:(UIViewController*)viewController;
@end

NS_ASSUME_NONNULL_END

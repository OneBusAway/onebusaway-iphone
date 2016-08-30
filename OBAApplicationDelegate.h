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

#import "OBANavigationTarget.h"
#import <GoogleAnalytics/GAITracker.h>
#import "OBAApplication.h"

NS_ASSUME_NONNULL_BEGIN

@class OBASearchResultsMapViewController;
@class OBARecentStopsViewController;
@class OBAInfoViewController;

@interface OBAApplicationDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,readonly) BOOL active;
@property(nonatomic, strong) id<GAITracker> tracker;

- (void)navigateToTarget:(OBANavigationTarget*)navigationTarget;
- (void)regionSelected;
@end

NS_ASSUME_NONNULL_END
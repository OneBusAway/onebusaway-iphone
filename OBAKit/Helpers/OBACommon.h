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

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBAErrorDomain;
extern const NSInteger kOBAErrorDuplicateEntity;
extern const NSInteger kOBAErrorMissingFieldInData;

// 3D Touch Quick Actions
extern NSString * const kApplicationShortcutMap;
extern NSString * const kApplicationShortcutRecents;
extern NSString * const kApplicationShortcutBookmarks;

// User Defaults Keys
extern NSString * const OBAOptInToTrackingDefaultsKey;
extern NSString * const OBAAllowReviewPromptsDefaultsKey;

/**
 We report "YES" and "NO" to Google Analytics in several places. This method
 DRYs those up.
 */
NSString * OBAStringFromBool(BOOL yn);

@interface OBACommon : NSObject
+ (void)setRunningInsideTests:(BOOL)runningInsideTests;
+ (BOOL)isRunningInsideTests;
@end

NS_ASSUME_NONNULL_END

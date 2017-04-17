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

typedef NS_ENUM(NSInteger, OBASearchType) {
    OBASearchTypeNone=0,
    OBASearchTypePending,
    OBASearchTypeRegion,
    OBASearchTypeRoute,
    OBASearchTypeStops,
    OBASearchTypeAddress,
    OBASearchTypePlacemark,
    OBASearchTypeStopId,
};

typedef NS_ENUM(NSInteger, OBANavigationTargetType) {
    OBANavigationTargetTypeUndefined=0,
    OBANavigationTargetTypeMap,
    OBANavigationTargetTypeSearchResults,
    OBANavigationTargetTypeRecentStops,
    OBANavigationTargetTypeBookmarks,
    OBANavigationTargetTypeContactUs,
};

typedef NS_ENUM(NSUInteger, OBAErrorCode) {
    OBAErrorCodeLocationAuthorizationFailed = 1002,
    OBAErrorCodePushNotificationAuthorizationDenied,
};

NSString * _Nullable NSStringFromOBASearchType(OBASearchType searchType);

extern NSString * const OBAErrorDomain;

// 3D Touch Quick Actions
extern NSString * const kApplicationShortcutMap;
extern NSString * const kApplicationShortcutRecents;
extern NSString * const kApplicationShortcutBookmarks;

// User Defaults Keys
extern NSString * const OBAOptInToTrackingDefaultsKey;
extern NSString * const OBAOptInToCrashReportingDefaultsKey;
extern NSString * const OBAAllowReviewPromptsDefaultsKey;
extern NSString * const OBAMapSelectedTypeDefaultsKey;
extern NSString * const OBADebugModeUserDefaultsKey;

// Server Addresses
extern NSString * const OBADeepLinkServerAddress;

/**
 We report "YES" and "NO" to Google Analytics in several places. This method
 DRYs those up.
 */
NSString * OBAStringFromBool(BOOL yn);

@interface OBACommon : NSObject
+ (void)setRunningInsideTests:(BOOL)runningInsideTests;
+ (BOOL)isRunningInsideTests;
@property(class,nonatomic,assign) BOOL debugMode;
@end

NS_ASSUME_NONNULL_END

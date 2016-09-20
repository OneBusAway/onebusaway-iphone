/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBAModelDAO.h>
#import <OBAKit/OBAModelService.h>
#import <OBAKit/OBALocationManager.h>
#import <OBAKit/OBAReachability.h>
#import <OBAKit/OBARegionHelper.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This notification is posted when the region changes and the app cannot generate an API URL from it.
 */
// TODO: give it a better name.
extern NSString *const kOBAApplicationSettingsRegionRefreshNotification;

@interface OBAApplication : NSObject
@property (nonatomic, strong, readonly) OBAReferencesV2 *references;
@property (nonatomic, strong, readonly) OBAModelDAO *modelDao;
@property (nonatomic, strong, readonly) OBAModelService *modelService;
@property (nonatomic, strong, readonly) OBALocationManager *locationManager;
@property (nonatomic, strong, readonly) OBARegionHelper *regionHelper;

/**
 *  This method should always be used to get an instance of this class.  This class should not be initialized directly.
 *
 *  @return singleton.   Thread safe.
 */
+ (instancetype)sharedApplication;

/**
 *  Call this when the object has been fully configured.
 */
- (void)start;

/**
 * Returns YES if the user has enabled darker system colors or reduced transparency.
 */
- (BOOL)useHighContrastUI;

/**
 * e.g. "2.4.2"
 */
- (NSString*)formattedAppVersion;

/**
 * e.g. "20151218.18"
 */
- (NSString*)formattedAppBuild;

/**
 * e.g. "2.4.2 (20151218.18)"
 */
- (NSString*)fullAppVersionString;

/**
 Starts listening for reachability change events.
 */
- (void)startReachabilityNotifier;

/**
 Stops listening for reachability change events.
 */
- (void)stopReachabilityNotifier;

/**
 Returns true if the server that OBA wants to connect to
 is currently reachable  and false if it is inaccessible.
 */
@property(nonatomic,assign,readonly) BOOL isServerReachable;

@end

NS_ASSUME_NONNULL_END

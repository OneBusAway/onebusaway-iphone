//
//  OBAApplication.h
//  OneBusAwaySDK
//
//  Created by Dima Belov on 4/25/15.
//
//  Copyright (c) 2015 Dima Belov
//  Copyright Sebastian Kießling
//  Copyright Ben Bodenmiller
//  Copyright Aaron Brethorst
//  Copyright Caitlin Bonnar
//  Copyright Jon Bell
//  Copyright Andrew Sullivan
//  Copyright Aengus McMillin
//

#import <Foundation/Foundation.h>
#import "OBAReferencesV2.h"
#import "OBAModelDAO.h"
#import "OBAModelService.h"
#import "OBALocationManager.h"
#import "OBAReachability.h"
#import "OBARegionHelper.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  This notification is posted in reference to a specific refreshSettings event, specifically when modelDao does not have an assigned region.
 */
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
 *  Refreshes the internal in-memory state by reading the latest persisted data.
 */
- (void)refreshSettings;

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

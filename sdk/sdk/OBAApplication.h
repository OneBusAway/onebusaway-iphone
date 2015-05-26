//
//  OBAApplication.h
//  OneBusAwaySDK
//
//  Created by Dima Belov on 4/25/15.
//  Copyright (c) 2015 One Bus Away. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBAReferencesV2.h"
#import "OBAModelDAO.h"
#import "OBAModelService.h"
#import "OBALocationManager.h"

/**
 *  This notification is posted in refernce to a specific refreshSettings event, specifically when modelDao does not have an assigned region.
 */
extern NSString *const kOBAApplicationSettingsRegionRefreshNotification;

@interface OBAApplication : NSObject

@property (nonatomic, strong, readonly) OBAReferencesV2 *references;
@property (nonatomic, strong, readonly) OBAModelDAO *modelDao;
@property (nonatomic, strong, readonly) OBAModelService *modelService;
@property (nonatomic, strong, readonly) OBALocationManager *locationManager;

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


@end

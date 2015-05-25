//
//  sdk.h
//  sdk
//
//  Created by Dima Belov on 4/25/15.
//  Copyright (c) 2015 One Bus Away. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBAReferencesV2.h"
#import "OBAModelDAO.h"
#import "OBAModelService.h"
#import "OBALocationManager.h"

@interface OBAApplication : NSObject

@property(nonatomic, strong, readonly) OBAReferencesV2 * references;
@property(nonatomic, strong, readonly) OBAModelDAO * modelDao;
@property(nonatomic, strong, readonly) OBAModelService * modelService;
@property(nonatomic, strong, readonly) OBALocationManager * locationManager;

/**
 *  This block, if set, is called whenever refreshSettings also refreshes a region.
 */
@property (nonatomic, copy) dispatch_block_t regionRefreshed;

/**
 *
 *  @return singleton.   Thread safe.
 */
+(instancetype) instance;

/**
 *  Call this when the object has been fully configured.
 */
-(void) start;

/**
 *  Refreshes the internal in-memory state by reading the latest persisted data.
 */
-(void) refreshSettings;


@end

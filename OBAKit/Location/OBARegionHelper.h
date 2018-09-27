//
//  OBARegionHelper.h
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 11.08.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

@import Foundation;
@import PromiseKit;
#import <OBAKit/OBARegionV2.h>
#import <OBAKit/OBALocationManager.h>
#import <OBAKit/OBAModelDAO.h>

@class OBARegionsService;

NS_ASSUME_NONNULL_BEGIN

@class OBARegionHelper;
@protocol OBARegionHelperDelegate <NSObject>
- (void)regionHelperShowRegionListController:(OBARegionHelper*)regionHelper;
- (void)regionHelperDidRefreshRegions:(OBARegionHelper*)regionHelper;
@end

@interface OBARegionHelper : NSObject
@property(nonatomic,strong) OBALocationManager *locationManager;
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,weak) id<OBARegionHelperDelegate> delegate;
@property(nonatomic,copy,readonly) NSArray<OBARegionV2*> *regionsWithin100Miles;
@property(nonatomic,copy,readonly) NSArray<OBARegionV2*> *regions;

- (instancetype)initWithLocationManager:(OBALocationManager*)locationManager modelService:(OBARegionsService*)modelService NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)setNearestRegion;
/**
 Refreshes the list of regions, and then finally returns the current authorization status. Or nil.

 @return nil or a promise that resolves to the current authorization status.
 */
- (nullable AnyPromise*)refreshData;

/**
 Selects the region with the specified identifier, if it exists.

 @param identifier The unique region identifier.
 @return true if a region is selected and false otherwise.
 */
- (BOOL)selectRegionWithIdentifier:(NSInteger)identifier;
@end

NS_ASSUME_NONNULL_END

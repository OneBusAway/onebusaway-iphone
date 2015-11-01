//
//  OBARegionHelper.h
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 11.08.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBAModelService.h"
#import "OBARegionV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBARegionHelper : NSObject <OBALocationManagerDelegate>
- (void)updateNearestRegion;
- (void)updateRegion;
@end

NS_ASSUME_NONNULL_END
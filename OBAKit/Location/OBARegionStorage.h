//
//  OBARegionStorage.h
//  OBAKit
//
//  Created by Aaron Brethorst on 4/2/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBARegionV2.h>
#import <OBAKit/OBAModelFactory.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBARegionStorage : NSObject
@property(nonatomic,copy) NSArray<OBARegionV2*> *regions;

- (instancetype)initWithModelFactory:(OBAModelFactory*)modelFactory NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

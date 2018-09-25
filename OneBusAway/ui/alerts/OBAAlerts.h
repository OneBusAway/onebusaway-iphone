//
//  OBAAlerts.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/31/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

@import UIKit;

@class OBAModelDAO;

NS_ASSUME_NONNULL_BEGIN

@interface OBAAlerts : NSObject
+ (UIAlertController*)locationServicesDisabledAlert;
+ (UIAlertController*)buildAddBookmarkGroupAlertWithModelDAO:(OBAModelDAO*)modelDAO completion:(void(^)(void))completion;

+ (UIAlertAction*)buildCancelButton;
@end

NS_ASSUME_NONNULL_END

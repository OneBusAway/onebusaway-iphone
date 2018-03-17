//
//  OBAAlarmNavigationTarget.h
//  OBAKit
//
//  Created by Aaron Brethorst on 2/21/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAKit.h>

@class OBAAlarm;

NS_ASSUME_NONNULL_BEGIN

@interface OBAAlarmNavigationTarget : OBANavigationTarget
@property(nonatomic,copy,nullable) OBAAlarm *alarm;

+ (instancetype)navigationTargetWithAlarm:(OBAAlarm*)alarm;
@end

NS_ASSUME_NONNULL_END

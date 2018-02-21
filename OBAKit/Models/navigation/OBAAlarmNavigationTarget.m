//
//  OBAAlarmNavigationTarget.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/21/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAAlarmNavigationTarget.h>
#import <OBAKit/OBAAlarm.h>

@implementation OBAAlarmNavigationTarget

+ (instancetype)navigationTargetWithAlarm:(OBAAlarm*)alarm {
    OBAAlarmNavigationTarget *target = [OBAAlarmNavigationTarget navigationTarget:OBANavigationTargetTypeRecentStops];
    target.alarm = alarm;
    return target;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        _alarm = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(alarm))];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_alarm forKey:NSStringFromSelector(@selector(alarm))];
}

- (id)copyWithZone:(NSZone *)zone {
    OBAAlarmNavigationTarget *target = [super copyWithZone:zone];
    target->_alarm = [_alarm copyWithZone:zone];

    return target;
}


@end

//
//  OBAAnimation.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAAnimation.h"

NSTimeInterval const OBALongAnimationDuration = 2.0;

@implementation OBAAnimation

+ (void)performAnimations:(void (^)(void))animations {
    [UIView animateWithDuration:[UIView inheritedAnimationDuration] animations:animations];
}

+ (void)performAnimations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration:[UIView inheritedAnimationDuration] animations:animations completion:completion];
}

@end

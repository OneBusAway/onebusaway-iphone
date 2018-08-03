//
//  OBAAnimation.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAAnimation.h>

NSTimeInterval const OBALongAnimationDuration = 2.0;

@implementation OBAAnimation

+ (void)performAnimations:(OBAVoidBlock)animations {
    [UIView animateWithDuration:[UIView inheritedAnimationDuration] animations:animations];
}

+ (void)performAnimations:(OBAVoidBlock)animations completion:(nullable OBACompletionBlock)completion {
    [self performAnimated:YES animations:animations completion:completion];
}

+ (void)performAnimated:(BOOL)animated animations:(OBAVoidBlock)animations {
    [self performAnimated:animated animations:animations completion:nil];
}

+ (void)performAnimated:(BOOL)animated animations:(OBAVoidBlock)animations completion:(nullable OBACompletionBlock)completion {
    if (animated) {
        [UIView animateWithDuration:[UIView inheritedAnimationDuration] animations:animations completion:completion];
    }
    else {
        animations();
        if (completion) completion(YES);
    }
}

@end

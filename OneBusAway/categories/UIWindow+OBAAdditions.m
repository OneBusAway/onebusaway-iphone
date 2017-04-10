//
//  UIWindow+OBAAdditions.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/9/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "UIWindow+OBAAdditions.h"

@implementation UIWindow (OBAAdditions)

- (void)oba_setRootViewController:(UIViewController *)rootViewController animated:(BOOL)animated {
    UIView *snapshot = nil;

    if (animated) {
        snapshot = [self snapshotViewAfterScreenUpdates:YES];
        [rootViewController.view addSubview:snapshot];
    }

    [self setRootViewController: rootViewController];

    if (animated) {
        [UIView animateWithDuration:[UIView inheritedAnimationDuration] animations:^{
            snapshot.layer.opacity = 0;
            snapshot.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5);
        } completion:^(BOOL finished) {
            [snapshot removeFromSuperview];
        }];
    }
}

@end

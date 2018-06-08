//
//  UIViewController+OBAContainment.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "UIViewController+OBAContainment.h"

@implementation UIViewController (OBAContainment)

- (void)oba_removeChildViewController:(UIViewController*)viewController {
    if (!viewController) {
        return;
    }

    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [self setOverrideTraitCollection:nil forChildViewController:viewController];
    [viewController removeFromParentViewController];
}

- (void)oba_prepareChildViewController:(UIViewController*)viewController {
    [viewController willMoveToParentViewController:self];
    [self setOverrideTraitCollection:self.traitCollection forChildViewController:viewController];
    [self addChildViewController:viewController];
}

- (void)oba_addChildViewController:(UIViewController*)viewController {
    [self oba_addChildViewController:viewController toView:self.view];
}

- (void)oba_addChildViewController:(UIViewController*)viewController toView:(UIView*)view {
    if (!viewController) {
        return;
    }

    [self oba_prepareChildViewController:viewController];
    viewController.view.frame = view.bounds;
    [view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

@end

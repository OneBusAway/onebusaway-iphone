//
//  UIViewController+OBAAdditions.m
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/3/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "UIViewController+OBAAdditions.h"
@import OBAKit;

@implementation UIViewController (OBAAdditions)

- (void)oba_presentViewController:(UIViewController*)viewController fromView:(UIView*)view {
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && view) {
        viewController.popoverPresentationController.sourceView = view;
        viewController.popoverPresentationController.sourceRect = view.bounds;
    }

    [self presentViewController:viewController animated:YES completion:nil];
}

- (BOOL)oba_traitCollectionHasCompactDimension {
    return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact ||
           self.traitCollection.verticalSizeClass   ==  UIUserInterfaceSizeClassCompact;
}

- (void)oba_presentPopoverViewController:(UIViewController*)viewController fromView:(UIView*)view {
    CGSize sz = CGSizeZero;

    if (viewController.view.subviews.count == 1 && [viewController.view.subviews[0] isKindOfClass:UIScrollView.class]) {
        UIScrollView *sv = viewController.view.subviews[0];
        sz = sv.contentSize;
    }
    else if (self.oba_traitCollectionHasCompactDimension) {
        CGFloat min = MIN(CGRectGetHeight(self.view.frame), CGRectGetWidth(self.view.frame));
        sz = CGSizeMake(min - 20, min - 20);
    }
    else {
        sz = CGSizeMake(350, 350); // arbitrary choice. Let's see how it looks.
    }

    UINavigationController *nav = [PopoverPresenter popoverMenuWith:viewController preferredContentSize:sz presentingView:view];
    [self presentViewController:nav animated:YES completion:nil];
}

@end

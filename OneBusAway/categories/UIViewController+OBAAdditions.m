//
//  UIViewController+OBAAdditions.m
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/3/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "UIViewController+OBAAdditions.h"

@implementation UIViewController (OBAAdditions)

- (void)oba_presentViewController:(UIViewController*)viewController fromView:(UIView*)view {
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && view) {
        viewController.popoverPresentationController.sourceView = view;
        viewController.popoverPresentationController.sourceRect = view.bounds;
    }

    [self presentViewController:viewController animated:YES completion:nil];
}

@end

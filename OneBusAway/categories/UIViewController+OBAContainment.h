//
//  UIViewController+OBAContainment.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (OBAContainment)

- (void)oba_removeChildViewController:(UIViewController*)viewController;

- (void)oba_prepareChildViewController:(UIViewController*)viewController;
- (void)oba_addChildViewController:(UIViewController*)viewController;
- (void)oba_addChildViewController:(UIViewController*)viewController toView:(UIView*)view;
@end

NS_ASSUME_NONNULL_END

//
//  UIViewController+OBAAdditions.h
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/3/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (OBAAdditions)

/**
 On an iPhone, this will modally present the view controller. On iPad, it
 configures the view controller to be presented from the provided view
 as a popover.

 @param viewController The view controller to present.
 @param view The optional presenting view for the modal presentation.
 */
- (void)oba_presentViewController:(UIViewController*)viewController fromView:(nullable UIView*)view;

/**
 Present a popover controller from the specified view on an iPhone or iPad. Tries to be clever about the presented content size.

 @param viewController The view controller that will be presented as a popover.
 @param view The view from which the popover will be presented.
 */
- (void)oba_presentPopoverViewController:(UIViewController*)viewController fromView:(UIView*)view;

/**
 True if either the horizontal or vertical size class for this view controller is compact,
 and false otherwise.
 */
@property(nonatomic,assign,readonly) BOOL oba_traitCollectionHasCompactDimension;

@end

NS_ASSUME_NONNULL_END

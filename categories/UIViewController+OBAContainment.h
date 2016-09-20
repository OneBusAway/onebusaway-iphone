//
//  UIViewController+OBAContainment.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (OBAContainment)

- (void)oba_removeChildViewController:(UIViewController*)viewController;
- (void)oba_addChildViewController:(UIViewController*)viewController;

@end

//
//  UINavigationController+oba_Additions.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "UINavigationController+oba_Additions.h"

@implementation UINavigationController (oba_Additions)

- (void)replaceViewController:(UIViewController*)viewController animated:(BOOL)animated {
    NSMutableArray * viewControllers = [NSMutableArray arrayWithArray:self.viewControllers];
    [viewControllers insertObject:viewController atIndex:[viewControllers count]-1];
    self.viewControllers = viewControllers;
    [self popViewControllerAnimated:animated];
}

@end

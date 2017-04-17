//
//  UIWindow+OBAAdditions.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/9/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import UIKit;

@interface UIWindow (OBAAdditions)
- (void)oba_setRootViewController:(UIViewController *)rootViewController animated:(BOOL)animated;
@end

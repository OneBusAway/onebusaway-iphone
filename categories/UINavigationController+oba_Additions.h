//
//  UINavigationController+oba_Additions.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationController (oba_Additions)
- (void)replaceViewController:(UIViewController*)viewController animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END

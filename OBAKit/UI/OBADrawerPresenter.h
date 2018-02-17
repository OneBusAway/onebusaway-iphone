//
//  OBADrawerPresenter.h
//  OBAKit
//
//  Created by Aaron Brethorst on 2/17/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@protocol OBADrawerPresenter<NSObject>
- (void)pushViewController:(UIViewController*)viewController animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END

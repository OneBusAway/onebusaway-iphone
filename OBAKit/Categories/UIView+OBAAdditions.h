//
//  UIView+OBAAdditions.h
//  OBAKit
//
//  Created by Aaron Brethorst on 3/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIView (OBAAdditions)
+ (instancetype)oba_autolayoutNew;
- (UIView*)oba_embedInWrapperView;

// Debug-only
- (void)printAutoLayoutTrace;
- (void)exerciseAmbiguityInLayoutRepeatedly:(BOOL)recursive;
@end

NS_ASSUME_NONNULL_END

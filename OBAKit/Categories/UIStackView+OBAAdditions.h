//
//  UIStackView+OBAAdditions.h
//  OBAKit
//
//  Created by Aaron Brethorst on 8/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIStackView (OBAAdditions)

+ (instancetype)oba_horizontalStackWithArrangedSubviews:(NSArray<UIView*>*)subviews;

+ (instancetype)oba_verticalStackWithArrangedSubviews:(NSArray<UIView*>*)subviews;

@end

NS_ASSUME_NONNULL_END

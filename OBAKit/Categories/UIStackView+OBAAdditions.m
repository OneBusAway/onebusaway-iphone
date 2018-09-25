//
//  UIStackView+OBAAdditions.m
//  OBAKit
//
//  Created by Aaron Brethorst on 8/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/UIStackView+OBAAdditions.h>

@implementation UIStackView (OBAAdditions)

+ (instancetype)oba_horizontalStackWithArrangedSubviews:(NSArray<UIView*>*)subviews {
    UIStackView *stack = [[self alloc] initWithArrangedSubviews:subviews];
    stack.axis = UILayoutConstraintAxisHorizontal;

    return stack;
}

+ (instancetype)oba_verticalStackWithArrangedSubviews:(NSArray<UIView*>*)subviews {
    UIStackView *stack = [[self alloc] initWithArrangedSubviews:subviews];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;

    return stack;

}

@end

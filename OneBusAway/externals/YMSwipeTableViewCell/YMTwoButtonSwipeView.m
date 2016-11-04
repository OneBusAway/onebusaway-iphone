//
//  YMTwoButtonSwipeView.m
//  YMSwipeTableViewCell
//
//  Created by aluong on 8/25/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "YMTwoButtonSwipeView.h"

static NSString * const kAction1Text = @"Button 1";
static NSString * const kAction2Text = @"Button 2";

@implementation YMTwoButtonSwipeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        OBAStackedButton *leftButton = [[OBAStackedButton alloc] init];
        [leftButton.titleLabel setNumberOfLines:0];
        leftButton.userInteractionEnabled = YES;
        leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        [leftButton setTitle:kAction1Text forState:UIControlStateNormal];
        [self addSubview:leftButton];
        [leftButton addTarget:self action:@selector(leftButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.leftButton = leftButton;
        
        OBAStackedButton *rightButton = [[OBAStackedButton alloc] init];
        [rightButton.titleLabel setNumberOfLines:0];
        rightButton.userInteractionEnabled = YES;
        rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        [rightButton setTitle:kAction2Text forState:UIControlStateNormal];
        [self addSubview:rightButton];
        [rightButton addTarget:self action:@selector(rightButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.rightButton = rightButton;
        
        // First button; pin it to the left edge.
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[leftButton]"
                                                                     options:0L
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(leftButton)]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftButton]|"
                                                                     options:0L
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(leftButton)]];
        
        // Subsequent button; pin it to the right edge of the preceding one, with equal width.
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[leftButton][rightButton(==leftButton)]|"
                                                                     options:0L
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(leftButton, rightButton)]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightButton]|"
                                                                     options:0L
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(rightButton)]];
    }
    return self;
}

# pragma mark - Cell Swipe State Change Blocks
- (void)didSwipeWithTranslation:(CGPoint)translation
{
    // Do something during a swipe
}

- (void)didChangeMode:(YATableSwipeMode)mode
{
    // Do something after the cell mode has changed
}

# pragma mark - Button Methods
- (void)leftButtonTapped:(id)sender
{
    if (self.leftButtonTappedActionBlock) {
        self.leftButtonTappedActionBlock();
    }
}

- (void)rightButtonTapped:(id)sender
{
    if (self.rightButtonTappedActionBlock) {
        self.rightButtonTappedActionBlock();
    }
}

@end

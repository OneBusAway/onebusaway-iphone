//
//  YMOneButtonSwipeView.m
//  YMSwipeTableViewCell
//
//  Created by aluong on 8/27/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "YMOneButtonSwipeView.h"

@implementation YMOneButtonSwipeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        _aButton = [[UIButton alloc] init];
        _aButton.backgroundColor = [self swipeColorButton];
        [_aButton.titleLabel setNumberOfLines:0];
        _aButton.userInteractionEnabled = YES;
        _aButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIImage *checkView = [UIImage imageNamed:@"lightGrey_checkmark"];
        [_aButton setImage:checkView forState:UIControlStateNormal];
        
        [_aButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_aButton];
        
        // constrain the button to fill the bounds of the superview
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_aButton]|"
                                                                     options:0L
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(_aButton)]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_aButton]|"
                                                                     options:0L
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(_aButton)]];
    }
    return self;
}

# pragma mark - Cell Swipe State Change Blocks
- (void)didSwipeWithTranslation:(CGPoint)translation
{
    CGFloat contentOffsetX = (CGFloat)fabs(translation.x);
    CGFloat textAlpha = contentOffsetX / CGRectGetWidth(self.bounds);
    self.aButton.imageView.alpha = textAlpha;
}

- (void)didChangeMode:(YATableSwipeMode)mode
{
    if ((mode == YATableSwipeModeLeftON) || (mode == YATableSwipeModeRightON)) {
        self.aButton.imageView.alpha = 1.0;
    }
}

# pragma mark - Button Methods
- (void)buttonTapped:(id)sender
{
    if (self.buttonTappedActionBlock) {
        self.buttonTappedActionBlock();
    }
}

# pragma mark - Helper Methods

- (UIColor *)swipeColorButton
{
    return [UIColor blueColor];
}
@end

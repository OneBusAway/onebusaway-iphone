//
//  BTBalloon.m
//
//  Created by Cameron Cooke on 10/03/2014.
//  Copyright (c) 2014 Brightec Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import "BTBalloon.h"
#import "BTBalloonArrow.h"
//#import <PureLayout.h>
@import Masonry;

typedef NS_ENUM(NSInteger, BTBalloonArrowPosition) {
    BTBalloonArrowPositionBelow,
    BTBalloonArrowPositionAbove
};


static CGFloat const arrowWidth = 35.0f;
static CGFloat const arrowHeight = 20.0f;
static CGFloat const margin = 10.0f;


@interface BTBalloon ()
@property (weak, nonatomic) UIWindow *window;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *label;
@property (nonatomic) UIButton *button;
@property (nonatomic) UIView *balloonView;
@property (nonatomic) BTBalloonArrow *arrowView;
@property (nonatomic) NSLayoutConstraint *arrowHorizontalConstraint;
@property (nonatomic) NSLayoutConstraint *arrowTopConstraint;
@property (nonatomic) NSLayoutConstraint *topConstraint;
@property (nonatomic) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) void (^callbackBlock)(void);
@end


@implementation BTBalloon


+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    @synchronized ([self class]) {
        if (sharedInstance == nil) {
            sharedInstance = [[self class] new];
        }
        return sharedInstance;
    }
}


- (id)init
{
    CGFloat smallestHeightToSatisifyConstraints = 200.0f;
    return [self initWithFrame:CGRectMake(0, 0, 280.0f, smallestHeightToSatisifyConstraints)];
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _window = [[UIApplication sharedApplication].delegate window];
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0;
        
        // defaults
        _buttonFont = [UIFont systemFontOfSize:16.0f];
        _buttonTextColor = [UIColor whiteColor];
        _buttonBackgroundColor = [UIColor blueColor];
        _balloonBackgroundColor = [UIColor colorWithWhite:0 alpha:0.85f];
        _textFont = [UIFont systemFontOfSize:16.0f];
        _textColor = [UIColor whiteColor];
        
        [self addArrowView];
        [self addBalloonView];
        
        [self.window addSubview:self];
    }
    return self;
}


# pragma mark -
# pragma mark Styling

- (void)setButtonFont:(UIFont *)buttonFont
{
    _buttonFont = buttonFont;
    self.button.titleLabel.font = self.buttonFont;
}


- (void)setButtonTextColor:(UIColor *)buttonTextColor
{
    _buttonTextColor = buttonTextColor;
    [self.button setTitleColor:self.buttonTextColor forState:UIControlStateNormal];
}


- (void)setButtonBackgroundColor:(UIColor *)buttonBackgroundColor
{
    _buttonBackgroundColor = buttonBackgroundColor;
    self.button.backgroundColor = self.buttonBackgroundColor;
}


- (void)setBalloonBackgroundColor:(UIColor *)balloonBackgroundColor
{
    _balloonBackgroundColor = balloonBackgroundColor;
    self.balloonView.backgroundColor = balloonBackgroundColor;
    self.arrowView.fillColour = balloonBackgroundColor;
}


- (void)setTextFont:(UIFont *)textFont
{
    _textFont = textFont;
    self.label.font = textFont;
}


- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    self.label.textColor = textColor;
}


# pragma mark -
# pragma mark Views

- (void)addArrowView
{
    // add arrow view
    self.arrowView = [[BTBalloonArrow alloc] initWithFrame:CGRectZero];
    self.arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    self.arrowView.backgroundColor = [UIColor clearColor];
    self.arrowView.opaque = NO;
    self.arrowView.fillColour = self.balloonBackgroundColor;
    [self addSubview:self.arrowView];
    [self.arrowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(arrowHeight));
        make.width.equalTo(@(arrowWidth));
    }];

    NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintWithItem:self.arrowView
                                                                            attribute:NSLayoutAttributeLeading
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self
                                                                            attribute:NSLayoutAttributeLeading
                                                                           multiplier:1.0f
                                                                             constant:0];
    [self addConstraint:horizontalConstraint];
    self.arrowHorizontalConstraint = horizontalConstraint;
    
    NSLayoutConstraint *arrowTopConstraint = [NSLayoutConstraint constraintWithItem:self.arrowView
                                                                          attribute:NSLayoutAttributeTop
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self
                                                                          attribute:NSLayoutAttributeTop
                                                                         multiplier:1.0f
                                                                           constant:0];
    self.arrowTopConstraint = arrowTopConstraint;
    [self addConstraint:arrowTopConstraint];
}


- (void)addBalloonView
{
    // add balloon view
    self.balloonView = [[UIView alloc] initWithFrame:CGRectZero];
    self.balloonView.translatesAutoresizingMaskIntoConstraints = NO;
    self.balloonView.backgroundColor = self.balloonBackgroundColor;
    [self addSubview:self.balloonView];
    [self.balloonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.equalTo(self);
    }];

    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.balloonView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0f
                                                                      constant:arrowHeight];
    [self addConstraint:topConstraint];
    self.topConstraint = topConstraint;
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.balloonView
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0f
                                                                         constant:0];
    [self addConstraint:bottomConstraint];
    self.bottomConstraint = bottomConstraint;
}


- (UIImageView *)imageView
{
    if (_imageView == nil) {
        _imageView = [UIImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return _imageView;
}


- (UIButton *)button
{
    if (_button == nil) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        _button.backgroundColor = self.buttonBackgroundColor;
        _button.titleLabel.font = self.buttonFont;
        [_button setTitleColor:self.buttonTextColor forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(buttonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
        [_button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@44);
        }];
    }
    
    return _button;
}


- (UILabel *)label
{
    if (_label == nil) {
        _label = [UILabel new];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.lineBreakMode = NSLineBreakByWordWrapping;
        _label.numberOfLines = 0;
        _label.textColor = self.textColor;
        _label.font = self.textFont;
        _label.textAlignment = NSTextAlignmentCenter;
        _label.preferredMaxLayoutWidth = self.bounds.size.width - (margin * 2);
    }
    
    return _label;
}


# pragma mark -
# pragma mark Layout

- (void)sizeFrameToFitContent
{
    // resize view to fit ballon content based on constraints
    CGSize fittingSize = [self.balloonView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGSize size = CGSizeMake(self.frame.size.width, fittingSize.height+arrowHeight);
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = CGRectIntegral(frame);
}

- (void)adjustTransformForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeRight:
            self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            self.transform =  CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI_2);
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            self.transform =  CGAffineTransformRotate(CGAffineTransformIdentity, M_PI);
            break;
            
        case UIInterfaceOrientationPortrait:
        default:
            self.transform = CGAffineTransformIdentity;
            break;
    }
}


# pragma mark -
# pragma mark Target/action

- (void)buttonWasTouched:(UIButton *)sender
{
    if (self.button.superview != nil && self.callbackBlock) {
        self.callbackBlock();
    }
}


# pragma mark -
# pragma mark Public

- (void)showWithTitle:(NSString *)title image:(UIImage *)image
{
    [self showWithTitle:title image:image anchorToView:nil];
}


- (void)showWithTitle:(NSString *)title image:(UIImage *)image anchorToView:(UIView *)view
{
    [self showWithTitle:title image:image anchorToView:view buttonTitle:nil buttonCallback:nil];
}


- (void)showWithTitle:(NSString *)title image:(UIImage *)image anchorToView:(UIView *)view buttonTitle:(NSString *)buttonTitle buttonCallback:(void (^)(void))callbackBlock
{
    [self showWithTitle:title image:image anchorToView:view buttonTitle:buttonTitle buttonCallback:callbackBlock afterDelay:0];
}


- (void)showWithTitle:(NSString *)title image:(UIImage *)image anchorToView:(UIView *)view buttonTitle:(NSString *)buttonTitle buttonCallback:(void (^)(void))callbackBlock afterDelay:(NSTimeInterval)delay
{
    self.transform = CGAffineTransformIdentity;

    [self updateTitle:title image:image button:buttonTitle buttonCallback:callbackBlock];

    if (view == nil) {
        [self hideArrow];
        self.center = self.window.center;
        self.frame = CGRectIntegral(self.frame);
    } else {
        [self anchorToView:view];
    }
    
    if (delay > 0) {
        [self performSelector:@selector(show) withObject:nil afterDelay:delay];
    } else {
        [self show];
    }
}


- (void)updateTitle:(NSString *)title image:(UIImage *)image button:(NSString *)buttonTitle buttonCallback:(void (^)(void))callbackBlock
{
    self.callbackBlock = nil;
    
    // remove existing subviews (this breaks all the constraints, nice!)
    if (_label && _label.superview != nil) {
        [self.label removeFromSuperview];
    }

    if (_button && _button.superview != nil) {
        [self.button removeFromSuperview];
    }

    if (_imageView && _imageView.superview != nil) {
        [self.imageView removeFromSuperview];
    }
    
    // update label
    self.label.text = title;
    [self.balloonView addSubview:self.label];
    [self.balloonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[label]-(10)-|" options:0 metrics:nil views:@{@"label": self.label}]];

    // add image
    if (image) {
        
        NSDictionary *viewsDictionary = @{@"label": self.label, @"image": self.imageView};
        
        self.imageView.image = image;
        [self.balloonView addSubview:self.imageView];
        
        // add constraints
        [self.balloonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[image]-(10)-|" options:0 metrics:nil views:viewsDictionary]];
        [self.balloonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[image]-(10)-[label]" options:0 metrics:nil views:viewsDictionary]];
        
    } else {
        
        // add constraints
        [self.balloonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[label]" options:0 metrics:nil views:@{@"label": self.label}]];
    }
    
    // add button
    if (buttonTitle) {
        
        NSDictionary *viewsDictionary = @{@"label": self.label, @"button": self.button};
        
        self.callbackBlock = callbackBlock;
        [self.button setTitle:buttonTitle forState:UIControlStateNormal];
        [self.balloonView addSubview:self.button];
        
        // add constraints
        [self.balloonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[button]-(10)-|" options:0 metrics:nil views:viewsDictionary]];
        [self.balloonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-(10)-[button]-(10)-|" options:0 metrics:nil views:viewsDictionary]];
        
    } else {
        // add constraints
        [self.balloonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-(10)-|" options:0 metrics:nil views:@{@"label": self.label}]];
    }

    [self.balloonView layoutIfNeeded];
    [self sizeFrameToFitContent];
}


- (void)anchorToView:(UIView *)view
{
    UIWindow *window = self.window;
    CGRect convertedFrame = [view.superview convertRect:view.frame toView:window];
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    
    // get the surrounding space
    CGFloat spaceAbove = CGRectGetMinY(convertedFrame);
    CGFloat spaceBelow = CGRectGetHeight(window.frame) - (spaceAbove + CGRectGetHeight(view.frame));
    
//    NSLog(@"Ballon size=%@", NSStringFromCGSize(self.frame.size));
//    NSLog(@"Space above=%f below=%f", spaceAbove, spaceBelow);
    
    // adjust this view's frame
    CGRect frame = self.frame;
    
    BTBalloonArrowPosition arrowPosition = BTBalloonArrowPositionAbove;
    if (height > spaceBelow && spaceAbove >= height) {
//        NSLog(@"Using space above");
        frame.origin.y = CGRectGetMinY(convertedFrame) - height;
        arrowPosition = BTBalloonArrowPositionBelow;
    } else if (height > spaceBelow) {
//        NSLog(@"Using space below but adjusting size of balloon to fit");
        frame.origin.y = CGRectGetMaxY(convertedFrame);
        frame.size.height = spaceBelow;
    } else {
//        NSLog(@"Using space below");
        frame.origin.y = CGRectGetMaxY(convertedFrame);
    }
    
    CGFloat x = CGRectGetMidX(convertedFrame) - (width / 2);
    x = MIN(x, CGRectGetWidth(window.frame) - width - margin);
    x = MAX(x, margin);
    
    frame.origin.x = x;
    self.frame = CGRectIntegral(frame);
    
    [self showArrow:arrowPosition];
    [self pointArrowAtView:view];
}


- (void)hide
{
    [self hideWithAnimation:YES];
}


- (void)hideWithAnimation:(BOOL)animated
{
//    NSLog(@"Hiding balloon");
    
    CGFloat duration = animated ? 0.3f : 0;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 0;
    } completion:nil];
}


- (void)show
{
    [self showWithAnimation:YES];
}


- (void)showWithAnimation:(BOOL)animated
{
//    NSLog(@"Showing balloon");
    
    [self.window bringSubviewToFront:self];
    
    CGFloat duration = animated ? 0.3f : 0;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 1.0f;
    } completion:nil];
}


# pragma mark -
# pragma mark Arrow

- (void)showArrow:(BTBalloonArrowPosition)position
{
    if (position == BTBalloonArrowPositionAbove) {
        self.topConstraint.constant = arrowHeight;
        self.bottomConstraint.constant = 0;
        self.arrowTopConstraint.constant = 0;
        self.arrowView.direction = BTBalloonArrowDirectionUp;
    } else {
        self.topConstraint.constant = 0;
        self.bottomConstraint.constant = -arrowHeight;
        self.arrowTopConstraint.constant = CGRectGetHeight(self.bounds) - arrowHeight;
        self.arrowView.direction = BTBalloonArrowDirectionDown;
    }
    
    self.arrowView.hidden = NO;
}


- (void)hideArrow
{
    self.topConstraint.constant = 0;
    self.bottomConstraint.constant = -arrowHeight;
    self.arrowTopConstraint.constant = 0;
    self.arrowView.hidden = YES;
}


- (void)centerArrow
{
    CGFloat x = self.balloonView.center.x - (arrowWidth / 2);
    [self setArrowPosition:x];
}


- (void)pointArrowAtView:(UIView *)view
{
    CGPoint centerPoint = [view.superview convertPoint:view.center toView:self.balloonView];
    CGFloat x = centerPoint.x - (arrowWidth / 2);
    [self setArrowPosition:x];
}


- (void)setArrowPosition:(CGFloat)positon
{
    // make sure balloon is restrained within the visible area of the balloon view
    CGFloat x = positon;
    x = MIN(x, CGRectGetWidth(self.balloonView.frame) - arrowWidth);
    x = MAX(x, 0);
    
    self.arrowHorizontalConstraint.constant = x;
}


@end

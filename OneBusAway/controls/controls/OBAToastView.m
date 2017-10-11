//
//  OBAToastView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBAToastView.h"
@import Masonry;
@import OBAKit;

@interface OBAToastView ()
@property(nonatomic,strong,readwrite) UILabel *label;
@property(nonatomic,strong,readwrite) UIButton *button;
@property(nonatomic,strong) UIStackView *stackView;
@property(nonatomic,strong) UIView *containerView;
@end

@implementation OBAToastView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        if ([OBATheme useHighContrastUI]) {
            _containerView = [[UIView alloc] initWithFrame:self.bounds];
            _containerView.backgroundColor = [UIColor darkGrayColor];
        }
        else {
            OBAVibrantBlurContainerView *blurView = [[OBAVibrantBlurContainerView alloc] initWithFrame:self.bounds];
            blurView.blurEffectStyle = UIBlurEffectStyleDark;
            _containerView = blurView;
        }
        [self addSubview:_containerView];
        [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        self.layer.cornerRadius = [OBATheme defaultCornerRadius];
        self.layer.masksToBounds = YES;

        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.numberOfLines = 0;
        _label.font = [OBATheme bodyFont];
        _label.textColor = [OBATheme darkBlurLabelTextColor];

        _button = [UIButton buttonWithType:UIButtonTypeSystem];
        _button.titleLabel.font = [OBATheme boldBodyFont];
        [_button setTitle:NSLocalizedString(@"toast_view.clear_search", @"Clear Search button text") forState:UIControlStateNormal];

        [_label setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        [_button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_label, _button]];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.spacing = [OBATheme defaultPadding];
        [self.contentView addSubview:_stackView];
        [_stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo([self contentView]).insets(UIEdgeInsetsMake(0, [OBATheme compactPadding], 0, [OBATheme compactPadding]));
        }];

        self.hidden = YES;
        self.alpha = 0;
    }
    return self;
}

- (UIView*)contentView {
    if ([self.containerView isKindOfClass:[OBAVibrantBlurContainerView class]]) {
        return ((OBAVibrantBlurContainerView*)self.containerView).vibrancyEffectView.contentView;
    }
    else {
        return self.containerView;
    }
}

#pragma mark - Hide/Show

- (void)showWithText:(NSString*)text withCancelButton:(BOOL)withCancelButton {
    self.label.text = text;

    self.button.hidden = !withCancelButton;

    if (self.hidden) {
        self.alpha = 0.f;
        self.hidden = NO;

        [OBAAnimation performAnimations:^{
            self.alpha = 1.f;
        }];
    }
}

- (void)dismiss {
    [OBAAnimation performAnimations:^{
        self.alpha = 0.f;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

@end

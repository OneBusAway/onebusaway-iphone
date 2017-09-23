//
//  OBAMapActivityIndicatorView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAMapActivityIndicatorView.h"
#import "OBAVibrantBlurContainerView.h"
@import OBAKit;
@import Masonry;

@interface OBAMapActivityIndicatorView ()
@property(nonatomic,strong) OBAVibrantBlurContainerView *blurContainer;
@property(nonatomic,strong) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation OBAMapActivityIndicatorView
@dynamic animating;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = [OBATheme defaultCornerRadius];

        _blurContainer = [[OBAVibrantBlurContainerView alloc] initWithFrame:self.bounds];
        _blurContainer.blurEffectStyle = UIBlurEffectStyleDark;
        _blurContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:_blurContainer];

        CGRect activityFrame = CGRectZero;
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:activityFrame];
        _activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        [_blurContainer.vibrancyEffectView.contentView addSubview:_activityIndicatorView];
        UIView *container = _blurContainer.vibrancyEffectView.contentView;
        [_activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(container);
        }];
    }
    return self;
}

- (void)setAnimating:(BOOL)animating {
    self.hidden = !animating;

    if (animating) {
        [self.activityIndicatorView startAnimating];
    }
    else {
        [self.activityIndicatorView stopAnimating];
    }
}

- (BOOL)animating {
    return self.activityIndicatorView.isAnimating;
}

- (CGSize)intrinsicContentSize {
    CGSize sz = self.activityIndicatorView.intrinsicContentSize;
    sz.width += OBATheme.defaultPadding;
    sz.height += OBATheme.defaultPadding;

    return sz;
}

@end

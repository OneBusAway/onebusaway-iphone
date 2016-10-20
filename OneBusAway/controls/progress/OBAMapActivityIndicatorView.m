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

        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectInset(self.bounds, [OBATheme compactPadding], [OBATheme compactPadding])];
        _activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        [_blurContainer.vibrancyEffectView.contentView addSubview:_activityIndicatorView];
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

@end

//
//  OBAVibrantBlurContainerView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAVibrantBlurContainerView.h"

@interface OBAVibrantBlurContainerView ()
@property(nonatomic,strong,readwrite) UIVisualEffectView *vibrancyEffectView;
@end

@implementation OBAVibrantBlurContainerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        _blurEffectStyle = UIBlurEffectStyleLight;
    }
    return self;
}

- (UIVisualEffectView*)vibrancyEffectView {
    if (!_vibrancyEffectView) {
        // Blur effect
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:self.blurEffectStyle];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        blurEffectView.frame = self.bounds;
        [self addSubview:blurEffectView];

        // Vibrancy effect
        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
        _vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
        _vibrancyEffectView.frame = blurEffectView.contentView.bounds;
        _vibrancyEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [blurEffectView.contentView addSubview:_vibrancyEffectView];
    }
    return _vibrancyEffectView;
}

@end

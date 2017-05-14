//
//  OBANavigationTitleView.m
//  org.onebusaway.iphone
//
//  Created by Cathy Oun on 5/13/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBANavigationTitleView.h"
#import <OBAKit/OBATheme.h>
@import Masonry;

@interface OBANavigationTitleView ()

@property(nonatomic,strong,readwrite) MarqueeLabel *titleLabel;
@property(nonatomic,strong,readwrite) MarqueeLabel *subtitleLabel;

@end

@implementation OBANavigationTitleView

- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle style:(OBAAppearanceNavBarTitleViewStyle)style {
    self = [super initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    if (self) {
        _titleLabel    = [[MarqueeLabel alloc] init];
        _subtitleLabel = [[MarqueeLabel alloc] init];

        [self addSubview:_subtitleLabel];
        [self addSubview:_titleLabel];
        
        switch (style) {
            case OBAAppearanceNavBarTitleViewStyleDefault:
            {
                [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.centerX.centerY.equalTo(self);
                }];
                _titleLabel.textAlignment = NSTextAlignmentCenter;
                _titleLabel.text = title;
                _titleLabel.font = [OBATheme titleFont];
                
                break;
            }
            case OBAAppearanceNavBarTitleViewStyleSubtitle:
                [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.right.equalTo(self);
                    make.top.equalTo(self).offset(5);
                    make.bottom.equalTo(self.subtitleLabel.mas_top);
                }];
                [_subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.right.equalTo(self);
                }];
                _titleLabel.font = [OBATheme bodyFont];
                _subtitleLabel.font = [OBATheme footnoteFont];
                _titleLabel.textAlignment = NSTextAlignmentCenter;
                _subtitleLabel.textAlignment = NSTextAlignmentCenter;
                _titleLabel.text = title;
                _subtitleLabel.text = subtitle;
                break;
        }
    }
    return self;
}


@end

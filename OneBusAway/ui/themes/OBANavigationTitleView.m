//
//  OBANavigationTitleView.m
//  org.onebusaway.iphone
//
//  Created by Cathy Oun on 5/13/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBANavigationTitleView.h"
#import <OBAKit/OBATheme.h>
@import MarqueeLabel;
@import Masonry;

@interface OBANavigationTitleView ()

@property(nonatomic,strong) MarqueeLabel *titleLabel;
@property(nonatomic,strong) MarqueeLabel *subtitleLabel;

@end

@implementation OBANavigationTitleView

- (instancetype)initWithTitle:(NSString *)title subtitle:(nullable NSString *)subtitle {
    self = [super initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.clipsToBounds = YES;

        _titleLabel = [[MarqueeLabel alloc] init];
        _titleLabel.font = [OBATheme boldBodyFont];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = title;

        NSMutableArray *subviews = [[NSMutableArray alloc] initWithArray:@[_titleLabel]];

        if (subtitle) {
            _subtitleLabel = [[MarqueeLabel alloc] init];
            _subtitleLabel.font = [OBATheme footnoteFont];
            _subtitleLabel.textAlignment = NSTextAlignmentCenter;
            _subtitleLabel.text = subtitle;

            [subviews addObject:_subtitleLabel];
        }

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:subviews];
        stack.axis = UILayoutConstraintAxisVertical;
        [self addSubview:stack];
        [stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

@end

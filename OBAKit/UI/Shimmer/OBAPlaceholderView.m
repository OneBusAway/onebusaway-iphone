//
//  OBAPlaceholderView.m
//  OBAKit
//
//  Created by Aaron Brethorst on 1/3/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAPlaceholderView.h>

static CGFloat const kLineThickness = 10.f;
static CGFloat const kMargin = 20.f;
static CGFloat const kTopMargin = 8.f;

@interface OBAPlaceholderView ()
@property(nonatomic,strong) UIView *topLine;
@property(nonatomic,strong) UIView *middleLine;
@property(nonatomic,strong) UIView *bottomLine;
@end

@implementation OBAPlaceholderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        UIColor *color = [UIColor colorWithWhite:0.9f alpha:1.f];

        _topLine = [[UIView alloc] initWithFrame:CGRectZero];
        _topLine.backgroundColor = color;

        _middleLine = [[UIView alloc] initWithFrame:CGRectZero];
        _middleLine.backgroundColor = color;

        _bottomLine = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomLine.backgroundColor = color;

        [self addSubview:_topLine];
        [self addSubview:_middleLine];
        [self addSubview:_bottomLine];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    CGSize sz = [super intrinsicContentSize];

    sz.width = self.frame.size.width;

    [self layoutLines];

    sz.height = CGRectGetMaxY(self.bottomLine.frame) + kTopMargin;

    return sz;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutLines];
}

- (void)layoutLines {
    CGFloat width = CGRectGetWidth(self.frame);

    CGFloat topLineWidth = width * 0.60f;
    CGRect topLineFrame = CGRectMake(kMargin, kTopMargin, topLineWidth, kLineThickness);
    self.topLine.frame = topLineFrame;

    CGFloat midLineOrigin = kTopMargin + (2 * kLineThickness);
    CGFloat midLineWidth = width * 0.8f;
    CGRect midLineFrame = CGRectMake(kMargin, midLineOrigin, midLineWidth, kLineThickness);
    self.middleLine.frame = midLineFrame;

    CGFloat bottomLineOrigin = midLineOrigin + (2 * kLineThickness);
    CGFloat bottomLineWidth = width * 0.5f;
    CGRect bottomLineFrame = CGRectMake(kMargin, bottomLineOrigin, bottomLineWidth, kLineThickness);
    self.bottomLine.frame = bottomLineFrame;
}

@end

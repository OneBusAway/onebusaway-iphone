//
//  OBAPlaceholderView.m
//  OBAKit
//
//  Created by Aaron Brethorst on 1/3/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAPlaceholderView.h>

static CGFloat const kLineThickness = 10.f;
static CGFloat const kTopMargin = 8.f;
static CGFloat const kWidth = 280.f;

@interface OBAPlaceholderView ()
@property(nonatomic,strong) UIView *topLine;
@property(nonatomic,strong) UIView *middleLine;
@property(nonatomic,strong) UIView *bottomLine;
@end

@implementation OBAPlaceholderView

- (instancetype)initWithNumberOfLines:(NSUInteger)numberOfLines {
    self = [super initWithFrame:CGRectZero];

    if (self) {
        UIColor *color = [UIColor colorWithWhite:0.9f alpha:1.f];

        _topLine = [[UIView alloc] initWithFrame:CGRectZero];
        _topLine.backgroundColor = color;
        [self addSubview:_topLine];

        _middleLine = [[UIView alloc] initWithFrame:CGRectZero];
        _middleLine.backgroundColor = color;
        [self addSubview:_middleLine];

        if (numberOfLines == 3) {
            _bottomLine = [[UIView alloc] initWithFrame:CGRectZero];
            _bottomLine.backgroundColor = color;
            [self addSubview:_bottomLine];
        }
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    CGSize sz = [super intrinsicContentSize];

//    sz.width = self.frame.size.width;
    sz.width = kWidth; // abxoxo how's this look?

    [self layoutLines];

    sz.height = CGRectGetMaxY(self.subviews[self.subviews.count - 1].frame) + kTopMargin;

    return sz;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutLines];
}

- (void)layoutLines {
    CGFloat topLineWidth = kWidth * 0.60f;
    CGRect topLineFrame = CGRectMake(0, kTopMargin, topLineWidth, kLineThickness);
    self.topLine.frame = topLineFrame;

    CGFloat midLineOrigin = kTopMargin + (2 * kLineThickness);
    CGFloat midLineWidth = kWidth * 0.8f;
    CGRect midLineFrame = CGRectMake(0, midLineOrigin, midLineWidth, kLineThickness);
    self.middleLine.frame = midLineFrame;

    if (self.bottomLine) {
        CGFloat bottomLineOrigin = midLineOrigin + (2 * kLineThickness);
        CGFloat bottomLineWidth = kWidth * 0.5f;
        CGRect bottomLineFrame = CGRectMake(0, bottomLineOrigin, bottomLineWidth, kLineThickness);
        self.bottomLine.frame = bottomLineFrame;
    }
}

@end

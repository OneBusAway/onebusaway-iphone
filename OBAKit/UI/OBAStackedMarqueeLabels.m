//
//  OBAStackedMarqueeLabels.m
//  OBAKit
//
//  Created by Aaron Brethorst on 1/6/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAStackedMarqueeLabels.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/UILabel+OBAAdditions.h>

@interface OBAStackedMarqueeLabels ()
@property(nonatomic,strong,readwrite) MarqueeLabel *topLabel;
@property(nonatomic,strong,readwrite) MarqueeLabel *bottomLabel;
@end

@implementation OBAStackedMarqueeLabels

- (instancetype)initWithWidth:(CGFloat)width {
    self = [super initWithFrame:CGRectZero];

    if (self) {
        _topLabel = [self.class buildMarqueeLabelWithWidth:width];
        _bottomLabel = [self.class buildMarqueeLabelWithWidth:width];

        CGFloat combinedLabelHeight = CGRectGetHeight(_topLabel.frame) + CGRectGetHeight(_bottomLabel.frame);
        [self addSubview:_topLabel];
        [self addSubview:_bottomLabel];

        self.frame = CGRectMake(0, 0, width, combinedLabelHeight);

        CGRect updateLabelFrame = _bottomLabel.frame;
        updateLabelFrame.origin.y = CGRectGetMaxY(_topLabel.frame);
        _bottomLabel.frame = updateLabelFrame;
    }
    return self;
}

#pragma mark - Private UI Stuff

+ (MarqueeLabel*)buildMarqueeLabelWithWidth:(CGFloat)width {
    MarqueeLabel *label = [[MarqueeLabel alloc] initWithFrame:CGRectMake(0, 0, width, 10)];
    label.font = [OBATheme boldFootnoteFont];
    label.trailingBuffer = [OBATheme defaultPadding];
    label.fadeLength = [OBATheme defaultPadding];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    [label oba_resizeHeightToFit];

    return label;
}

@end

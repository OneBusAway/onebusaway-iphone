//
//  OBAWalkableCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 11/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAWalkableCell.h"
@import OBAKit;
@import Masonry;
#import "OBAAnimation.h"

@interface OBAWalkableCell ()
@property(nonatomic,strong) OBACanvasView *triangleView;
@property(nonatomic,strong) UIImageView *walkImageView;
@end

@implementation OBAWalkableCell
@synthesize tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UIColor *backgroundColor = [OBATheme OBAGreen];

        CGFloat barHeight = [OBATheme defaultPadding];
        CGFloat triangleWidth = 30.f;
        CGFloat triangleHeight = 15.f;

        [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(barHeight+triangleHeight));
        }];

        CGFloat xPoint = CGRectGetWidth(self.frame) - triangleWidth - self.layoutMargins.right - [OBATheme defaultPadding];
        CGFloat yPoint = 0.f;

        _triangleView = [[OBACanvasView alloc] initWithFrame:CGRectMake(xPoint, [OBATheme defaultPadding], triangleWidth, triangleHeight) drawRectBlock:^(CGRect rect) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(0, yPoint)];
            [path addLineToPoint:CGPointMake(triangleWidth/2.f, triangleHeight)];
            [path addLineToPoint:CGPointMake(triangleWidth, yPoint)];
            [path closePath];
            [backgroundColor set];
            [path fill];
        }];
        _triangleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:_triangleView];

        UIView *barView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), barHeight)];
        barView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        barView.backgroundColor = backgroundColor;
        [self addSubview:barView];

        UIImage *walkImage = [[UIImage imageNamed:@"walkTransport"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _walkImageView = [[UIImageView alloc] initWithImage:walkImage];
        _walkImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        _walkImageView.tintColor = [UIColor whiteColor];
        _walkImageView.contentMode = UIViewContentModeScaleAspectFit;
        _walkImageView.frame = CGRectApplyAffineTransform(_triangleView.frame, CGAffineTransformMakeTranslation(0, -6.f));
        [self addSubview:_walkImageView];
    }

    return self;
}

@end

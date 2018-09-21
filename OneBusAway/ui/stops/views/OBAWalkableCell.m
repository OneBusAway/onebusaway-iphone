//
//  OBAWalkableCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 11/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAWalkableCell.h"
@import Masonry;
#import "OBAWalkableRow.h"

@interface OBAWalkableCell ()
@property(nonatomic,strong) OBACanvasView *fillView;
@property(nonatomic,strong) UIImageView *walkImageView;
@property(nonatomic,strong) UILabel *distanceLabel;
@end

@implementation OBAWalkableCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UIColor *backgroundColor = [OBATheme OBAGreen];
        UIFont *distanceLabelFont = [OBATheme footnoteFont];

        CGFloat barHeight = [@"jJmyg89" sizeWithAttributes:@{NSFontAttributeName: distanceLabelFont}].height + 2;
        CGFloat triangleHeight = 8.f;
        CGFloat triangleWidth = 20.f;
        CGFloat triangleOffsetFromRight = 18.f;

        UIView *sizingView = [UIView oba_autolayoutNew];
        [self.contentView addSubview:sizingView];
        [sizingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(barHeight+triangleHeight)).priorityMedium();
            make.edges.equalTo(self.contentView);
        }];

        _fillView = [[OBACanvasView alloc] initWithFrame:self.bounds drawRectBlock:^(CGRect rect) {
            UIBezierPath *path = [UIBezierPath bezierPath];

            CGPoint topLeft = CGPointMake(0, 0);
            CGPoint topRight = CGPointMake(CGRectGetMaxX(rect), 0);
            CGPoint bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect) - triangleHeight);
            CGPoint triangleStart = CGPointMake(CGRectGetMaxX(rect) - triangleOffsetFromRight, CGRectGetMaxY(rect) - triangleHeight);
            CGPoint triangleMid = CGPointMake(triangleStart.x - (triangleWidth / 2.f), CGRectGetMaxY(rect));
            CGPoint triangleEnd = CGPointMake(triangleStart.x - triangleWidth, triangleStart.y);
            CGPoint bottomLeft = CGPointMake(0, bottomRight.y);

            [path moveToPoint:topLeft];
            [path addLineToPoint:topRight];
            [path addLineToPoint:bottomRight];
            [path addLineToPoint:triangleStart];
            [path addLineToPoint:triangleMid];
            [path addLineToPoint:triangleEnd];
            [path addLineToPoint:bottomLeft];
            [path addLineToPoint:topLeft];

            [path closePath];
            [backgroundColor set];
            [path fill];
        }];
        _fillView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:_fillView];

        _distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 2, CGRectGetWidth(self.frame) - triangleWidth - triangleOffsetFromRight - 4, CGRectGetHeight(self.frame) - triangleHeight - 4)];
        _distanceLabel.font = distanceLabelFont;
        _distanceLabel.textColor = [UIColor whiteColor];
        _distanceLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        _distanceLabel.textAlignment = NSTextAlignmentRight;
        [_fillView addSubview:_distanceLabel];

        UIImage *walkImage = [[UIImage imageNamed:@"walkTransport"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _walkImageView = [[UIImageView alloc] initWithImage:walkImage];
        _walkImageView.tintColor = [UIColor whiteColor];
        _walkImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        _walkImageView.contentMode = UIViewContentModeScaleAspectFill;
        _walkImageView.frame = CGRectMake(CGRectGetMaxX(_distanceLabel.frame) + 4, 6, triangleWidth - 2, (barHeight+triangleHeight- 4)/2.f);

        [_fillView addSubview:_walkImageView];
    }

    return self;
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];

    self.distanceLabel.text = nil;
}

#pragma mark - Table Data

- (void)setTableRow:(OBAWalkableRow *)row {
    OBAGuardClass(row, OBAWalkableRow) else {
        return;
    }

    _tableRow = [row copy];

    self.distanceLabel.text = [self walkableRow].text;
}

- (OBAWalkableRow*)walkableRow {
    return (OBAWalkableRow*)self.tableRow;
}

@end

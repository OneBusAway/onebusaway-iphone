//
//  OBATimelineBarCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/16/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATimelineBarCell.h"
#import "OBATimelineBarRow.h"
@import OBAKit;
@import Masonry;

CGFloat const OBATimelineBubbleSize = 30.f;
CGFloat const OBATimelineWidth = 1.f;

@interface OBATimelineBarCell ()
@property(nonatomic,strong) UIView *timelineBarView;
@property(nonatomic,strong) UILabel *label;
@end

@implementation OBATimelineBarCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

        UIView *barView = [[UIView alloc] initWithFrame:CGRectZero];
        barView.backgroundColor = [UIColor lightGrayColor];
        [self.contentView addSubview:barView];
        [barView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.and.bottom.equalTo(self.contentView);
            make.left.equalTo(@(OBATimelineBubbleSize / 2.f + self.layoutMargins.left));
            make.width.equalTo(@(OBATimelineWidth));
        }];
        _timelineBarView = barView;

        UIView *bottomBorderLine = [[UIView alloc] initWithFrame:CGRectZero];
        bottomBorderLine.backgroundColor = [OBATheme tableViewSeparatorLineColor];
        [self addSubview:bottomBorderLine];
        [bottomBorderLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(0.5f));
            make.left.bottom.and.right.equalTo(self).insets(UIEdgeInsetsMake(0, self.layoutMargins.left + OBATimelineBubbleSize + [OBATheme defaultPadding], 0, 0));
        }];

        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.numberOfLines = 0;
        [self.contentView addSubview:_label];
        [_label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(barView).offset(23);
            make.top.right.and.bottom.equalTo(self.contentView);
            make.height.greaterThanOrEqualTo(@50);
        }];
    }
    return self;
}

#pragma mark - Table Row

- (void)setTableRow:(OBABaseRow *)tableRow {
    OBAGuardClass(tableRow, OBATimelineBarRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.label.text = [self timelineBarRow].title;
    self.accessoryType = [self timelineBarRow].accessoryType;
}

- (OBATimelineBarRow*)timelineBarRow {
    return (OBATimelineBarRow*)self.tableRow;
}

@end

//
//  OBABookmarkedRouteLoadingCell.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/3/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABookmarkedRouteLoadingCell.h>
#import <OBAKit/OBATableRow.h>
#import <OBAKit/OBABookmarkedRouteRow.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/FBShimmeringView.h>
#import <OBAKit/OBAPlaceholderView.h>
#import <OBAKit/OBATheme.h>

@import Masonry;

@interface OBABookmarkedRouteLoadingCell ()
@property(nonatomic,copy,readonly) OBABookmarkedRouteRow *tableDataRow;

@property(nonatomic,strong) UILabel *topLabel;
@property(nonatomic,strong) FBShimmeringView *shimmeringView;
@property(nonatomic,strong) OBAPlaceholderView *placeholderView;
@end

@implementation OBABookmarkedRouteLoadingCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        _topLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _topLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _shimmeringView = [[FBShimmeringView alloc] initWithFrame:CGRectZero];
        _placeholderView = [[OBAPlaceholderView alloc] initWithFrame:CGRectZero];
        _shimmeringView.contentView = _placeholderView;
        _shimmeringView.shimmering = YES;

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_topLabel, _shimmeringView]];
        stack.axis = UILayoutConstraintAxisVertical;
        [self.contentView addSubview:stack];
        [stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(OBATheme.defaultEdgeInsets);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.topLabel.text = nil;
}

- (void)setTableRow:(OBATableRow *)tableRow {
    OBAGuardClass(tableRow, OBABookmarkedRouteRow) else {
        return;
    }
    _tableRow = [tableRow copy];

    self.topLabel.attributedText = self.tableDataRow.attributedTopLine ?: self.tableDataRow.attributedMiddleLine;
}

- (OBABookmarkedRouteRow*)tableDataRow {
    return (OBABookmarkedRouteRow*)self.tableRow;
}

@end

//
//  OBAPlaceholderCell.m
//  OBAKit
//
//  Created by Aaron Brethorst on 1/4/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAPlaceholderCell.h>
#import <OBAKit/OBAPlaceholderView.h>
#import <OBAKit/FBShimmeringView.h>
#import <OBAKit/OBATheme.h>
@import Masonry;

@interface OBAPlaceholderCell ()
@property(nonatomic,strong) FBShimmeringView *shimmeringView;
@property(nonatomic,strong) OBAPlaceholderView *placeholderView;
@end

@implementation OBAPlaceholderCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        _shimmeringView = [[FBShimmeringView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_shimmeringView];
        [_shimmeringView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(OBATheme.defaultEdgeInsets);
        }];

        _placeholderView = [[OBAPlaceholderView alloc] initWithNumberOfLines:3];
        _shimmeringView.contentView = _placeholderView;
        [_placeholderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_shimmeringView);
        }];

        _shimmeringView.shimmering = YES;
    }

    return self;
}

@end

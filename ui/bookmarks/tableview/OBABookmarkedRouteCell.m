//
//  OBABookmarkedRouteCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarkedRouteCell.h"
#import "OBAClassicDepartureView.h"
#import "OBABookmarkedRouteRow.h"
#import "OBATableRow.h"

#import <Masonry/Masonry.h>
#import <OBAKit/OBAUIBuilder.h>
#import <OBAKit/OBABookmarkV2.h>
#import "OBAArrivalAndDepartureSectionBuilder.h"
#import "OBALabelActivityIndicatorView.h"

@interface OBABookmarkedRouteCell ()
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) OBAClassicDepartureView *departureView;
@property(nonatomic,strong) OBALabelActivityIndicatorView *activityIndicatorView;
@end

@implementation OBABookmarkedRouteCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.contentView.clipsToBounds = YES;
        self.contentView.frame = self.bounds;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

        _titleLabel = [OBAUIBuilder label];
        _titleLabel.font = [OBATheme subtitleFont];
        _titleLabel.numberOfLines = 0;
        [self.contentView addSubview:_titleLabel];

        _departureView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_departureView];

        _activityIndicatorView = [[OBALabelActivityIndicatorView alloc] initWithFrame:CGRectZero];
        _activityIndicatorView.hidden = YES;
        [self.contentView addSubview:_activityIndicatorView];

        [self setupConstraints];
    }
    return self;
}

- (void)setupConstraints {
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.and.right.equalTo(self.contentView).insets(self.layoutMargins);
    }];

    void (^constraintBlock)(MASConstraintMaker *make) = ^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.left.right.and.bottom.equalTo(self.contentView).insets(self.layoutMargins);
        make.height.greaterThanOrEqualTo(@40);
    };

    [self.departureView mas_makeConstraints:constraintBlock];
    [self.activityIndicatorView mas_makeConstraints:constraintBlock];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.titleLabel.text = nil;

    [self.departureView prepareForReuse];

    [self.activityIndicatorView prepareForReuse];
}

- (void)setTableRow:(OBATableRow *)tableRow
{
    OBAGuardClass(tableRow, OBABookmarkedRouteRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.titleLabel.text = [self tableDataRow].bookmark.name;

    if ([self tableDataRow].nextDeparture) {
        self.activityIndicatorView.hidden = YES;
        [self.activityIndicatorView stopAnimating];
        self.departureView.departureRow = [OBAArrivalAndDepartureSectionBuilder createDepartureRow:[self tableDataRow].nextDeparture];
    }
    else if ([self tableDataRow].state == OBABookmarkedRouteRowStateLoading) {
        [self.activityIndicatorView startAnimating];
        self.activityIndicatorView.hidden = NO;
    }
    else { // error state.
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView stopAnimating];
        self.activityIndicatorView.textLabel.text = [self tableDataRow].supplementaryMessage;
    }
}

- (OBABookmarkedRouteRow*)tableDataRow {
    return (OBABookmarkedRouteRow*)self.tableRow;
}

@end

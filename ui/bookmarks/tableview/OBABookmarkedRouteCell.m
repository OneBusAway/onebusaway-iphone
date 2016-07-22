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

@interface OBABookmarkedRouteCell ()
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) OBAClassicDepartureView *departureView;
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
        _titleLabel.numberOfLines = 0;
        [self.contentView addSubview:_titleLabel];

        _departureView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_departureView];

        [self setupConstraints];
    }
    return self;
}

- (void)setupConstraints {
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.and.right.equalTo(self.contentView).insets(self.layoutMargins);
    }];

    [self.departureView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.left.right.and.bottom.equalTo(self.contentView).insets(self.layoutMargins);
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.titleLabel.text = nil;

    self.departureView.routeNameLabel.text = nil;
    self.departureView.destinationLabel.text = nil;
    self.departureView.timeAndStatusLabel.text = nil;
    self.departureView.minutesUntilDepartureLabel.text = nil;
}

- (void)setTableRow:(OBATableRow *)tableRow
{
    OBAGuardClass(tableRow, OBABookmarkedRouteRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.titleLabel.text = [self tableDataRow].bookmark.name;

    if ([self tableDataRow].nextDeparture) {
        self.departureView.classicDepartureRow = [OBAArrivalAndDepartureSectionBuilder createDepartureRow:[self tableDataRow].nextDeparture];
    }
}

- (OBABookmarkedRouteRow*)tableDataRow {
    return (OBABookmarkedRouteRow*)self.tableRow;
}

@end

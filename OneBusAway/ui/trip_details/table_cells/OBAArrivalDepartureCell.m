//
//  OBAArrivalDepartureCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalDepartureCell.h"
#import "OBAArrivalDepartureRow.h"
@import OBAKit;
@import Masonry;

static CGFloat const kImageViewSize = 30.f;
static CGFloat const kTimelineWidth = 1.f;

@interface OBAArrivalDepartureCell ()
@property(nonatomic,strong) UIView *timelineBarView;
@property(nonatomic,strong) OBAValue1ContentsView *value1ContentsView;
@end

@implementation OBAArrivalDepartureCell
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
            make.left.equalTo(@(kImageViewSize / 2.f + self.layoutMargins.left));
            make.width.equalTo(@(kTimelineWidth));
        }];
        _timelineBarView = barView;

        _value1ContentsView = [[OBAValue1ContentsView alloc] initWithFrame:CGRectZero];

        [self.contentView addSubview:_value1ContentsView];

        [_value1ContentsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).insets(self.layoutMargins);
            make.top.right.and.bottom.equalTo(self.contentView);
            make.height.greaterThanOrEqualTo(@50);
        }];

        UIImageView *imageView = _value1ContentsView.imageView;

        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(imageView.mas_width);
            make.width.equalTo(@(kImageViewSize));
        }];

        UIView *bottomBorderLine = [[UIView alloc] initWithFrame:CGRectZero];
        bottomBorderLine.backgroundColor = [OBATheme tableViewSeparatorLineColor];
        [self addSubview:bottomBorderLine];
        [bottomBorderLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(0.5f));
            make.left.bottom.and.right.equalTo(self).insets(UIEdgeInsetsMake(0, self.layoutMargins.left + kImageViewSize + [OBATheme defaultPadding], 0, 0));
        }];
    }

    return self;
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];

    [self.value1ContentsView prepareForReuse];

    self.value1ContentsView.imageView.accessibilityLabel = nil;
    self.value1ContentsView.imageView.hidden = NO;
}

#pragma mark - OBATableCell

- (void)setTableRow:(OBABaseRow *)tableRow {

    OBAGuardClass(tableRow, OBAArrivalDepartureRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.accessoryType = [self departureRow].accessoryType;

    if ([self departureRow].closestStopToVehicle) {
        UIImage *image = [OBAStopIconFactory imageForRouteType:[self departureRow].routeType];
        self.value1ContentsView.imageView.image = [OBAImageHelpers circleImageWithSize:CGSizeMake(kImageViewSize, kImageViewSize) contents:image strokeColor:[OBATheme OBADarkGreen]];

        NSString *accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"arrival_departure_cell.closest_stop", @"The vehicle is currently closest to <STOP NAME>"), [self departureRow].title];
        self.value1ContentsView.imageView.accessibilityLabel = accessibilityLabel;
    }
    else if ([self departureRow].selectedStopForRider) {
        UIImage *walkImage = [UIImage imageNamed:@"walkTransport"];
        self.value1ContentsView.imageView.image = [OBAImageHelpers circleImageWithSize:CGSizeMake(kImageViewSize, kImageViewSize) contents:walkImage strokeColor:OBATheme.mapUserLocationColor];
    }
    else {
        self.value1ContentsView.imageView.image = [OBAImageHelpers circleImageWithSize:CGSizeMake(kImageViewSize, kImageViewSize) contents:nil];
    }

    self.value1ContentsView.textLabel.text = [self departureRow].title;

    self.value1ContentsView.detailTextLabel.text = [self departureRow].subtitle;
}

- (OBAArrivalDepartureRow*)departureRow {
    return (OBAArrivalDepartureRow*)[self tableRow];
}

@end

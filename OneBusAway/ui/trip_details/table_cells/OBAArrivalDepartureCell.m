//
//  OBAArrivalDepartureCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalDepartureCell.h"
#import "OBAArrivalDepartureRow.h"
@import Masonry;

#define kDebugColors NO

static CGFloat const kImageViewSize = 30.f;
static CGFloat const kTimelineWidth = 1.f;

@interface OBAArrivalDepartureCell ()
@property(nonatomic,strong) UIImageView *statusImageView;
@property(nonatomic,strong) UIView *timelineBarView;
@property(nonatomic,strong) UILabel *stopLabel;
@property(nonatomic,strong) OBAOccupancyStatusView *occupancyStatusView;
@property(nonatomic,strong) UIView *occupancyStatusWrapper;
@end

// abxoxo - next up: populate this cell with occupancy status info.

@implementation OBAArrivalDepartureCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.clipsToBounds = YES;

        [self.contentView addSubview:self.timelineBarView];
        [self.timelineBarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.and.bottom.equalTo(self.contentView);
            make.left.equalTo(@(kImageViewSize / 2.f + self.layoutMargins.left));
            make.width.equalTo(@(kTimelineWidth));
        }];

        UIView *imageWrapper = [self.statusImageView oba_embedInWrapperViewWithConstraints:NO];
        [self.statusImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(imageWrapper);
            make.leading.trailing.equalTo(imageWrapper);
            make.width.and.height.equalTo(@(kImageViewSize));
        }];

        UIStackView *outerStack = [UIStackView oba_horizontalStackWithArrangedSubviews:@[imageWrapper, self.stopLabel, self.occupancyStatusWrapper]];
        outerStack.spacing = OBATheme.defaultPadding;
        [self.contentView addSubview:outerStack];
        [outerStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(OBATheme.compactPadding, self.oba_leadingTrailingMargins.left, OBATheme.compactPadding, self.oba_leadingTrailingMargins.right));
        }];

        UIView *bottomBorderLine = [UIView oba_autolayoutNew];
        bottomBorderLine.backgroundColor = [OBATheme tableViewSeparatorLineColor];
        [self addSubview:bottomBorderLine];
        [bottomBorderLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(0.5f));
            make.left.bottom.and.right.equalTo(self).insets(UIEdgeInsetsMake(0, self.layoutMargins.left + kImageViewSize + [OBATheme defaultPadding], 0, 0));
        }];

        if (kDebugColors) {
            imageWrapper.backgroundColor = UIColor.magentaColor;
            self.statusImageView.backgroundColor = UIColor.blueColor;
            self.stopLabel.backgroundColor = UIColor.redColor;
            self.occupancyStatusWrapper.backgroundColor = UIColor.orangeColor;
            self.occupancyStatusView.highlightedBackgroundColor = UIColor.clearColor;
            self.occupancyStatusView.defaultBackgroundColor = UIColor.clearColor;
            self.contentView.backgroundColor = UIColor.blueColor;
        }
    }

    return self;
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];

    self.stopLabel.text = nil;
    self.statusImageView.image = nil;
    self.occupancyStatusView.occupancyStatus = OBAOccupancyStatusUnknown;
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
        self.statusImageView.image = [OBAImageHelpers circleImageWithSize:CGSizeMake(kImageViewSize, kImageViewSize) contents:image strokeColor:[OBATheme OBADarkGreen]];

        NSString *accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"arrival_departure_cell.closest_stop", @"The vehicle is currently closest to <STOP NAME>"), [self departureRow].title];
        self.statusImageView.accessibilityLabel = accessibilityLabel;
    }
    else if ([self departureRow].selectedStopForRider) {
        UIImage *walkImage = [UIImage imageNamed:@"walkTransport"];
        self.statusImageView.image = [OBAImageHelpers circleImageWithSize:CGSizeMake(kImageViewSize, kImageViewSize) contents:walkImage strokeColor:OBATheme.mapUserLocationColor];
    }
    else {
        self.statusImageView.image = [OBAImageHelpers circleImageWithSize:CGSizeMake(kImageViewSize, kImageViewSize) contents:nil];
    }

    NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc] initWithString:self.departureRow.title attributes:@{NSFontAttributeName: OBATheme.bodyFont}];
    [labelText appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];

    NSAttributedString *timeText = [[NSAttributedString alloc] initWithString:self.departureRow.subtitle attributes:@{NSFontAttributeName: OBATheme.bodyFont, NSForegroundColorAttributeName: UIColor.darkGrayColor}];
    [labelText appendAttributedString:timeText];

    self.stopLabel.attributedText = labelText;

    // abxoxo - remove the next line!
    self.departureRow.historicalOccupancyStatus = OBAOccupancyStatusFull;

    self.occupancyStatusView.occupancyStatus = self.departureRow.historicalOccupancyStatus;
}

- (OBAArrivalDepartureRow*)departureRow {
    return (OBAArrivalDepartureRow*)[self tableRow];
}

- (UIImageView*)statusImageView {
    if (!_statusImageView) {
        _statusImageView = [UIImageView oba_autolayoutNew];
        [_statusImageView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_statusImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _statusImageView;
}

- (OBAOccupancyStatusView*)occupancyStatusView {
    if (!_occupancyStatusView) {
        _occupancyStatusView = [[OBAOccupancyStatusView alloc] initWithImage:[UIImage imageNamed:@"silhouette"]];
        [_occupancyStatusView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _occupancyStatusView;
}

- (UIView*)occupancyStatusWrapper {
    if (!_occupancyStatusWrapper) {
        UIView *wrapper = [self.occupancyStatusView oba_embedInWrapperViewWithConstraints:NO];
        wrapper.mas_key = @"occupancyWrapper";
        [self.occupancyStatusView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.centerY.equalTo(wrapper);
        }];
        wrapper.clipsToBounds = YES;
        _occupancyStatusWrapper = wrapper;
    }
    return _occupancyStatusWrapper;
}

- (UIView*)timelineBarView {
    if (!_timelineBarView) {
        UIView *barView = [[UIView alloc] initWithFrame:CGRectZero];
        barView.backgroundColor = [UIColor lightGrayColor];
        _timelineBarView = barView;
    }
    return _timelineBarView;
}

- (UILabel*)stopLabel {
    if (!_stopLabel) {
        _stopLabel = [OBAAutoLabel oba_autolayoutNew];
        _stopLabel.numberOfLines = 0;
        [_stopLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_stopLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_stopLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_stopLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _stopLabel;
}

@end

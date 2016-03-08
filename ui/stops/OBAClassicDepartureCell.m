//
//  OBAClassicDepartureCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicDepartureCell.h"
#import <Masonry/Masonry.h>
#import "OBAClassicDepartureRow.h"
#import "OBADepartureCellHelpers.h"

#define kUseDebugColors 0

@interface OBAClassicDepartureCell ()
@property(nonatomic,strong) UILabel *routeNameLabel;
@property(nonatomic,strong) UILabel *destinationLabel;
@property(nonatomic,strong) UILabel *timeAndStatusLabel;
@property(nonatomic,strong) UILabel *minutesUntilDepartureLabel;
@end

@implementation OBAClassicDepartureCell
@synthesize tableRow = _tableRow;

/*
                | [ Destination ] |
 [ Route Name ] | --VERT  STACK-- | [ Minutes to Dep ]
                | [ Time/Status ] |
 
 */

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {

        if (kUseDebugColors) {
            self.contentView.backgroundColor = [UIColor blueColor];
        }

        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        _routeNameLabel = ({
            UILabel *l = [[UILabel alloc] init];
            l.minimumScaleFactor = 0.8f;
            l.adjustsFontSizeToFitWidth = YES;
            l.font = [OBATheme bodyFont];

            if (kUseDebugColors) {
                l.backgroundColor = [UIColor greenColor];
            }
            l;
        });

        _destinationLabel = ({
            UILabel *l = [[UILabel alloc] init];
            l.numberOfLines = 0;
            l.minimumScaleFactor = 0.8f;
            l.adjustsFontSizeToFitWidth = YES;
            l.font = [OBATheme bodyFont];
            l.textAlignment = NSTextAlignmentCenter;

            if (kUseDebugColors) {
                l.backgroundColor = [UIColor redColor];
            }

            l;
        });

        _timeAndStatusLabel = ({
            UILabel *l = [[UILabel alloc] init];
            l.numberOfLines = 1;
            l.minimumScaleFactor = 0.8f;
            l.adjustsFontSizeToFitWidth = YES;
            l.font = [OBATheme bodyFont];
            l.textAlignment = NSTextAlignmentCenter;

            if (kUseDebugColors) {
                l.backgroundColor = [UIColor purpleColor];
            }
            
            l;
        });

        _minutesUntilDepartureLabel = ({
            UILabel *l = [[UILabel alloc] init];
            l.minimumScaleFactor = 0.8f;
            l.adjustsFontSizeToFitWidth = YES;
            l.font = [OBATheme bodyFont];
            l.textAlignment = NSTextAlignmentRight;

            if (kUseDebugColors) {
                l.backgroundColor = [UIColor yellowColor];
            }

            l;
        });

        UIStackView *centerStack = ({
            UIStackView *sv = [[UIStackView alloc] initWithArrangedSubviews:@[_destinationLabel, _timeAndStatusLabel]];
            sv.axis = UILayoutConstraintAxisVertical;
            sv.distribution = UIStackViewDistributionFillProportionally;
            sv.layoutMarginsRelativeArrangement = YES;
            sv.layoutMargins = UIEdgeInsetsMake(0, [OBATheme defaultPadding] / 2.f, 0, [OBATheme defaultPadding] / 2.f);
            sv.distribution = UIStackViewDistributionEqualSpacing;
            sv;
        });

        UIStackView *horizontalStack = ({
            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_routeNameLabel, centerStack, _minutesUntilDepartureLabel]];
            stack.axis = UILayoutConstraintAxisHorizontal;
            stack.distribution = UIStackViewDistributionEqualSpacing;
            stack.layoutMarginsRelativeArrangement = YES;
            stack.layoutMargins = self.layoutMargins; //UIEdgeInsetsMake(0, self.layoutMargins.left, 0, self.layoutMargins.right);
            stack;
        });
        [self.contentView addSubview:horizontalStack];
        [horizontalStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
    }

    return self;
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];

    self.routeNameLabel.text = nil;
    self.destinationLabel.text = nil;
    self.timeAndStatusLabel.text = nil;
    self.minutesUntilDepartureLabel.text = nil;
}

#pragma mark - OBATableCell

- (void)setTableRow:(OBATableRow *)tableRow {

    OBAGuardClass(tableRow, OBAClassicDepartureRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.routeNameLabel.text = [self classicDepartureRow].routeName;
    self.destinationLabel.text = [self classicDepartureRow].destination;
    self.timeAndStatusLabel.attributedText = [OBADepartureCellHelpers attributedDepartureTime:[self classicDepartureRow].formattedNextDepartureTime
                                                                                   statusText:[self classicDepartureRow].statusText
                                                                              departureStatus:[self classicDepartureRow].departureStatus];

    self.minutesUntilDepartureLabel.text = [self classicDepartureRow].formattedMinutesUntilNextDeparture;
    self.minutesUntilDepartureLabel.textColor = [OBADepartureCellHelpers colorForStatus:[self classicDepartureRow].departureStatus];
}

- (OBAClassicDepartureRow*)classicDepartureRow {
    return (OBAClassicDepartureRow*)[self tableRow];
}

@end

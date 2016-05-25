//
//  OBAClassicDepartureView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicDepartureView.h"
#import <Masonry/Masonry.h>
#import "OBAClassicDepartureRow.h"
#import "OBADepartureCellHelpers.h"

#define kUseDebugColors 0

@interface OBAClassicDepartureView ()
@property(nonatomic,strong,readwrite) UILabel *routeNameLabel;
@property(nonatomic,strong,readwrite) UILabel *destinationLabel;
@property(nonatomic,strong,readwrite) UILabel *timeAndStatusLabel;
@property(nonatomic,strong,readwrite) UILabel *minutesUntilDepartureLabel;
@end

@implementation OBAClassicDepartureView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        _routeNameLabel = ({
            UILabel *l = [[UILabel alloc] init];
            l.minimumScaleFactor = 0.8f;
            l.adjustsFontSizeToFitWidth = YES;
            l.font = [OBATheme bodyFont];
            [l setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

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
            [l setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

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
            sv.layoutMargins = UIEdgeInsetsMake(0, [OBATheme halfDefaultPadding], 0, [OBATheme halfDefaultPadding]);
            sv.distribution = UIStackViewDistributionEqualSpacing;
            sv;
        });

        UIStackView *horizontalStack = ({
            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_routeNameLabel, centerStack, _minutesUntilDepartureLabel]];
            stack.axis = UILayoutConstraintAxisHorizontal;
            stack.distribution = UIStackViewDistributionEqualSpacing;
            stack.layoutMarginsRelativeArrangement = YES;
            stack.layoutMargins = UIEdgeInsetsMake([OBATheme halfDefaultPadding], self.layoutMargins.left, [OBATheme halfDefaultPadding], 0);
            stack;
        });
        [self addSubview:horizontalStack];
        [horizontalStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

- (void)setClassicDepartureRow:(OBAClassicDepartureRow *)classicDepartureRow {
    if (_classicDepartureRow == classicDepartureRow) {
        return;
    }

    _classicDepartureRow = [classicDepartureRow copy];

    self.routeNameLabel.text = [self classicDepartureRow].routeName;
    self.destinationLabel.text = [self classicDepartureRow].destination;
    self.timeAndStatusLabel.attributedText = [OBADepartureCellHelpers attributedDepartureTime:[self classicDepartureRow].formattedNextDepartureTime
                                                                                   statusText:[self classicDepartureRow].statusText
                                                                              departureStatus:[self classicDepartureRow].departureStatus];

    self.minutesUntilDepartureLabel.text = [self classicDepartureRow].formattedMinutesUntilNextDeparture;
    self.minutesUntilDepartureLabel.textColor = [OBADepartureCellHelpers colorForStatus:[self classicDepartureRow].departureStatus];
}
@end

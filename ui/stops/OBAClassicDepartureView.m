//
//  OBAClassicDepartureView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicDepartureView.h"
#import <Masonry/Masonry.h>
#import "OBADepartureRow.h"
#import "OBADepartureCellHelpers.h"
#import "OBAAnimation.h"
#import "OBADepartureTimeLabel.h"

#define kUseDebugColors 0

@interface OBAClassicDepartureView ()
@property(nonatomic,strong) UILabel *routeLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *minutesLabel;
@end

@implementation OBAClassicDepartureView

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.clipsToBounds = YES;

        _routeLabel = ({
            UILabel *l = [[UILabel alloc] init];
            l.numberOfLines = 0;
            [l setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            l;
        });

        UIView *minutesWrapper = [[UIView alloc] initWithFrame:CGRectZero];
        minutesWrapper.clipsToBounds = YES;

        _minutesLabel = ({
            OBADepartureTimeLabel *l = [[OBADepartureTimeLabel alloc] init];
            l.font = [OBATheme bodyFont];
            l.textAlignment = NSTextAlignmentRight;
            [l setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            l;
        });
        [minutesWrapper addSubview:_minutesLabel];

        [_minutesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(minutesWrapper);
            make.left.and.right.equalTo(minutesWrapper);
        }];

        if (kUseDebugColors) {
            self.backgroundColor = [UIColor purpleColor];
            _routeLabel.backgroundColor = [UIColor greenColor];
            _minutesLabel.backgroundColor = [UIColor magentaColor];
            minutesWrapper.backgroundColor = [UIColor redColor];
        }

        UIStackView *horizontalStack = ({
            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_routeLabel, minutesWrapper]];
            stack.axis = UILayoutConstraintAxisHorizontal;
            stack.distribution = UIStackViewDistributionFill;
            stack;
        });
        [self addSubview:horizontalStack];
        [horizontalStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

#pragma mark - Reuse

- (void)prepareForReuse {
    self.routeLabel.text = nil;
    self.minutesLabel.text = nil;
}

#pragma mark - Row Logic

- (void)setDepartureRow:(OBADepartureRow *)departureRow {
    if (_departureRow == departureRow) {
        return;
    }

    _departureRow = [departureRow copy];

    [self renderRouteLabel];
    [self.minutesLabel renderTimeLabel:[self departureRow].formattedMinutesUntilNextDeparture forStatus:[self departureRow].departureStatus];
}

#pragma mark - Label Logic

- (void)renderRouteLabel {
    // TODO: clean me up once we've verified that users aren't losing their minds over the change.
    NSString *firstLineText = nil;

    if ([self departureRow].destination) {
        firstLineText = [NSString stringWithFormat:NSLocalizedString(@"%@ to %@\r\n", @"Route formatting string. e.g. 10 to Downtown Seattle<NEWLINE>"), [self departureRow].routeName, [self departureRow].destination];
    }
    else {
        firstLineText = [NSString stringWithFormat:@"%@\r\n", [self departureRow].routeName];
    }

    NSMutableAttributedString *routeText = [[NSMutableAttributedString alloc] initWithString:firstLineText attributes:@{NSFontAttributeName: [OBATheme bodyFont]}];

    [routeText addAttribute:NSFontAttributeName value:[OBATheme boldBodyFont] range:NSMakeRange(0, [self departureRow].routeName.length)];

    NSAttributedString *departureTime = [OBADepartureCellHelpers attributedDepartureTime:[self departureRow].formattedNextDepartureTime
                                                                              statusText:[self departureRow].statusText
                                                                         departureStatus:[self departureRow].departureStatus];

    [routeText appendAttributedString:departureTime];

    self.routeLabel.attributedText = routeText;
}

@end

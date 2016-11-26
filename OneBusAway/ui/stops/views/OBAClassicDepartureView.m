//
//  OBAClassicDepartureView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicDepartureView.h"
@import Masonry;
@import OBAKit;
#import "OBADepartureRow.h"
#import "OBAAnimation.h"
#import "OBADepartureTimeLabel.h"

#define kUseDebugColors 0

@interface OBAClassicDepartureView ()
@property(nonatomic,strong) UILabel *routeLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *leadingLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *centerLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *trailingLabel;
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

        _leadingLabel = [self.class departureTimeLabel];
        UIView *leadingWrapper = [self.class wrapLabel:_leadingLabel];

        _centerLabel = [self.class departureTimeLabel];
        UIView *centerWrapper = [self.class wrapLabel:_centerLabel];

        _trailingLabel = [self.class departureTimeLabel];
        UIView *trailingWrapper = [self.class wrapLabel:_trailingLabel];

        if (kUseDebugColors) {
            self.backgroundColor = [UIColor purpleColor];
            _routeLabel.backgroundColor = [UIColor greenColor];

            _leadingLabel.backgroundColor = [UIColor magentaColor];
            leadingWrapper.backgroundColor = [UIColor redColor];

            _centerLabel.backgroundColor = [UIColor magentaColor];
            centerWrapper.backgroundColor = [UIColor blueColor];

            _trailingLabel.backgroundColor = [UIColor magentaColor];
            trailingWrapper.backgroundColor = [UIColor brownColor];
        }

        UIStackView *horizontalStack = ({
            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_routeLabel, leadingWrapper, centerWrapper, trailingWrapper]];
            stack.axis = UILayoutConstraintAxisHorizontal;
            stack.distribution = UIStackViewDistributionFill;
            stack.spacing = [OBATheme compactPadding];
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
    self.leadingLabel.text = nil;
    self.centerLabel.text = nil;
    self.trailingLabel.text = nil;
}

#pragma mark - Row Logic

- (void)setDepartureRow:(OBADepartureRow *)departureRow {
    if (_departureRow == departureRow) {
        return;
    }

    _departureRow = [departureRow copy];

    [self renderRouteLabel];

    if ([self departureRow].upcomingDepartures.count > 0) {
        [self setDepartureStatus:[self departureRow].upcomingDepartures[0] forLabel:self.leadingLabel];
    }

    if ([self departureRow].upcomingDepartures.count > 1) {
        [self setDepartureStatus:[self departureRow].upcomingDepartures[1] forLabel:self.centerLabel];
    }

    if ([self departureRow].upcomingDepartures.count > 2) {
        [self setDepartureStatus:[self departureRow].upcomingDepartures[2] forLabel:self.trailingLabel];
    }
}

- (void)setDepartureStatus:(OBAUpcomingDeparture*)departure forLabel:(OBADepartureTimeLabel*)label {
    [label setText:[OBADateHelpers formatMinutesUntilDate:departure.departureDate] forStatus:departure.departureStatus];
}

#pragma mark - Label Logic

- (void)renderRouteLabel {
    // TODO: clean me up once we've verified that users aren't losing their minds over the change.
    NSString *firstLineText = nil;

    if ([self departureRow].destination) {
        firstLineText = [NSString stringWithFormat:NSLocalizedString(@"text_route_to_orientation_newline_params", @"Route formatting string. e.g. 10 to Downtown Seattle<NEWLINE>"), [self departureRow].routeName, [self departureRow].destination];
    }
    else {
        firstLineText = [NSString stringWithFormat:@"%@\r\n", [self departureRow].routeName];
    }

    NSMutableAttributedString *routeText = [[NSMutableAttributedString alloc] initWithString:firstLineText attributes:@{NSFontAttributeName: [OBATheme bodyFont]}];

    [routeText addAttribute:NSFontAttributeName value:[OBATheme boldBodyFont] range:NSMakeRange(0, [self departureRow].routeName.length)];

    OBAUpcomingDeparture *upcoming = [self departureRow].upcomingDepartures.firstObject;
    NSAttributedString *departureTime = [OBADepartureCellHelpers attributedDepartureTimeWithStatusText:[self departureRow].statusText upcomingDeparture:upcoming];

    [routeText appendAttributedString:departureTime];

    self.routeLabel.attributedText = routeText;
}

#pragma mark - Label and Wrapper Builders

+ (OBADepartureTimeLabel*)departureTimeLabel {
    OBADepartureTimeLabel *label = [[OBADepartureTimeLabel alloc] init];
    label.font = [OBATheme bodyFont];
    label.textAlignment = NSTextAlignmentRight;
    [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    return label;
}

+ (UIView*)wrapLabel:(OBADepartureTimeLabel*)label {
    UIView *minutesWrapper = [[UIView alloc] initWithFrame:CGRectZero];
    minutesWrapper.clipsToBounds = YES;
    [minutesWrapper addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(minutesWrapper);
        make.left.and.right.equalTo(minutesWrapper);
    }];

    return minutesWrapper;
}

@end

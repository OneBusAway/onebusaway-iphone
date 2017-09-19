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

#define kUseDebugColors NO

@interface OBAClassicDepartureView ()
@property(nonatomic,strong,readwrite) UIButton *contextMenuButton;
@property(nonatomic,strong) UILabel *routeLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *leadingLabel;
@property(nonatomic,strong) UIView *leadingWrapper;

@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *centerLabel;
@property(nonatomic,strong) UIView *centerWrapper;

@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *trailingLabel;
@property(nonatomic,strong) UIView *trailingWrapper;
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
            [l setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [l setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [l setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
            l;
        });

        _leadingLabel = [self.class departureTimeLabel];
        _leadingWrapper = [self.class wrapLabel:_leadingLabel];

        _centerLabel = [self.class departureTimeLabel];
        _centerWrapper = [self.class wrapLabel:_centerLabel];

        _trailingLabel = [self.class departureTimeLabel];
        _trailingWrapper = [self.class wrapLabel:_trailingLabel];

        _contextMenuButton = [OBAUIBuilder contextMenuButton];

        if (kUseDebugColors) {
            self.backgroundColor = [UIColor purpleColor];
            _routeLabel.backgroundColor = [UIColor greenColor];

            _leadingLabel.backgroundColor = [UIColor magentaColor];
            _leadingWrapper.backgroundColor = [UIColor redColor];

            _centerLabel.backgroundColor = [UIColor magentaColor];
            _centerWrapper.backgroundColor = [UIColor blueColor];

            _trailingLabel.backgroundColor = [UIColor magentaColor];
            _trailingWrapper.backgroundColor = [UIColor brownColor];

            _contextMenuButton.backgroundColor = [UIColor yellowColor];
        }

        UIStackView *horizontalStack = ({
            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_routeLabel, _leadingWrapper, _centerWrapper, _trailingWrapper, _contextMenuButton]];
            stack.axis = UILayoutConstraintAxisHorizontal;
            stack.distribution = UIStackViewDistributionFill;
            stack.spacing = [OBATheme compactPadding];
            stack;
        });
        [self addSubview:horizontalStack];

        [horizontalStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        [_contextMenuButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@40);
            make.height.greaterThanOrEqualTo(@40);
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
        self.leadingWrapper.hidden = NO;
        [self setDepartureStatus:[self departureRow].upcomingDepartures[0] forLabel:self.leadingLabel];
    }
    else {
        self.leadingWrapper.hidden = YES;
    }

    if ([self departureRow].upcomingDepartures.count > 1) {
        self.centerWrapper.hidden = NO;
        [self setDepartureStatus:[self departureRow].upcomingDepartures[1] forLabel:self.centerLabel];
    }
    else {
        self.centerWrapper.hidden = YES;
    }

    if ([self departureRow].upcomingDepartures.count > 2) {
        self.trailingWrapper.hidden = NO;
        [self setDepartureStatus:[self departureRow].upcomingDepartures[2] forLabel:self.trailingLabel];
    }
    else {
        self.centerWrapper.hidden = YES;
    }
}

- (void)setDepartureStatus:(OBAUpcomingDeparture*)departure forLabel:(OBADepartureTimeLabel*)label {
    label.accessibilityLabel = [OBADateHelpers formatAccessibilityLabelMinutesUntilDate:departure.departureDate];
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
    [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
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

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
@property(nonatomic,strong,readwrite) UILabel *leadingMinutesLabel;
@property(nonatomic,strong,readwrite) UILabel *centerMinutesLabel;
@property(nonatomic,strong,readwrite) UILabel *trailingMinutesLabel;
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

        _leadingMinutesLabel = [self.class buildLabel];
        _centerMinutesLabel = [self.class buildLabel];
        _trailingMinutesLabel = [self.class buildLabel];

        if (kUseDebugColors) {
            self.backgroundColor = [UIColor purpleColor];
            _routeLabel.backgroundColor = [UIColor greenColor];
            _leadingMinutesLabel.backgroundColor = [UIColor magentaColor];
            _centerMinutesLabel.backgroundColor = [UIColor blueColor];
            _trailingMinutesLabel.backgroundColor = [UIColor redColor];
        }

        UIStackView *horizontalStack = ({
            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_routeLabel, _leadingMinutesLabel, _centerMinutesLabel, _trailingMinutesLabel]];
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

+ (UILabel*)buildLabel {
    UILabel *l = [[UILabel alloc] init];
    l.font = [OBATheme bodyFont];
    [l setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    return l;
}

#pragma mark - Reuse

- (void)prepareForReuse {
    self.routeLabel.text = nil;
    self.leadingMinutesLabel.text = nil;
    self.centerMinutesLabel.text = nil;
    self.trailingMinutesLabel.text = nil;
}

#pragma mark - Row Logic

- (void)setDepartureRow:(OBADepartureRow *)departureRow {
    if (_departureRow == departureRow) {
        return;
    }

    _departureRow = [departureRow copy];

    [self renderRouteLabel];
    [self renderMinutesLabels];
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

    NSString *prependedText = nil;
    if ([self departureRow].upcomingDepartures.count > 1) {
        prependedText = NSLocalizedString(@"Next: ", @"Used in context of a departure. e.g. Next: 1:38PM - on time");
    }

    NSAttributedString *departureTime = [OBADepartureCellHelpers attributedDepartureTime:[self departureRow].formattedNextDepartureTime
                                                                              statusText:[self departureRow].statusText
                                                                         departureStatus:[self departureRow].departureStatus
                                                                           prependedText:prependedText];

    [routeText appendAttributedString:departureTime];

    self.routeLabel.attributedText = routeText;
}

- (void)renderMinutesLabels {

    NSArray *upcomingDepartures = [self departureRow].upcomingDepartures;

    if (upcomingDepartures.count > 0) {
        self.leadingMinutesLabel.text = [OBADepartureCellHelpers formatDateAsMinutes:upcomingDepartures[0]];
    }

    if (upcomingDepartures.count > 1) {
        self.centerMinutesLabel.text = [OBADepartureCellHelpers formatDateAsMinutes:upcomingDepartures[1]];
    }

    if (upcomingDepartures.count > 2) {
        self.trailingMinutesLabel.text = [OBADepartureCellHelpers formatDateAsMinutes:upcomingDepartures[2]];
    }
}

@end

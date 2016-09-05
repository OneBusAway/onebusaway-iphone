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
#import "OBAAnimation.h"

#define kUseDebugColors 0

@interface OBAClassicDepartureView ()
@property(nonatomic,assign) BOOL firstRenderPass;
@property(nonatomic,strong) UILabel *routeLabel;
@property(nonatomic,strong,readwrite) UILabel *minutesLabel;

@property(nonatomic,copy) NSString *previousMinutesText;
@property(nonatomic,copy) UIColor *previousMinutesColor;
@end

@implementation OBAClassicDepartureView

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.clipsToBounds = YES;
        _firstRenderPass = YES;

        _routeLabel = ({
            UILabel *l = [[UILabel alloc] init];
            l.numberOfLines = 0;
            [l setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            l;
        });

        UIView *minutesWrapper = [[UIView alloc] initWithFrame:CGRectZero];
        minutesWrapper.clipsToBounds = YES;

        _minutesLabel = ({
            UILabel *l = [[UILabel alloc] init];
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

- (void)setClassicDepartureRow:(OBAClassicDepartureRow *)classicDepartureRow {
    if (_classicDepartureRow == classicDepartureRow) {
        return;
    }

    _classicDepartureRow = [classicDepartureRow copy];

    [self renderRouteLabel];
    [self renderMinutesLabel];
}

- (void)renderRouteLabel {
    // TODO: clean me up once we've verified that users aren't losing their minds over the change.
    NSString *firstLineText = [NSString stringWithFormat:NSLocalizedString(@"%@ to %@\r\n", @"Route formatting string. e.g. 10 to Downtown Seattle<NEWLINE>"), [self classicDepartureRow].routeName, [self classicDepartureRow].destination];

    NSMutableAttributedString *routeText = [[NSMutableAttributedString alloc] initWithString:firstLineText attributes:@{NSFontAttributeName: [OBATheme bodyFont]}];

    [routeText addAttribute:NSFontAttributeName value:[OBATheme boldBodyFont] range:NSMakeRange(0, [self classicDepartureRow].routeName.length)];

    NSAttributedString *departureTime = [OBADepartureCellHelpers attributedDepartureTime:[self classicDepartureRow].formattedNextDepartureTime
                                                                              statusText:[self classicDepartureRow].statusText
                                                                         departureStatus:[self classicDepartureRow].departureStatus];

    [routeText appendAttributedString:departureTime];

    self.routeLabel.attributedText = routeText;
}

- (void)renderMinutesLabel {
    NSString *formattedMinutes = [self classicDepartureRow].formattedMinutesUntilNextDeparture;
    UIColor *formattedColor = [OBADepartureCellHelpers colorForStatus:[self classicDepartureRow].departureStatus];

    BOOL textChanged = ![formattedMinutes isEqual:self.previousMinutesText];
    BOOL colorChanged = ![formattedColor isEqual:self.previousMinutesColor];

    self.previousMinutesText = formattedMinutes;
    self.minutesLabel.text = formattedMinutes;

    self.previousMinutesColor = formattedColor;
    self.minutesLabel.textColor = formattedColor;

    // don't animate the first rendering of the cell.
    if (self.firstRenderPass) {
        self.firstRenderPass = NO;
        return;
    }

    if (textChanged || colorChanged) {
        [self animateLabelChange];
    }
}

- (void)animateLabelChange {
    self.minutesLabel.layer.backgroundColor = [OBATheme propertyChangedColor].CGColor;
    [UIView animateWithDuration:OBALongAnimationDuration animations:^{
        self.minutesLabel.layer.backgroundColor = self.backgroundColor.CGColor;
    }];
}

@end

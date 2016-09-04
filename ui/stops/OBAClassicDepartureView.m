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
@property(nonatomic,strong) UILabel *routeLabel;
@property(nonatomic,strong,readwrite) UILabel *minutesLabel;
@end

@implementation OBAClassicDepartureView

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        _routeLabel = ({
            UILabel *l = [[UILabel alloc] init];
            l.numberOfLines = 0;
            [l setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            l;
        });

        _minutesLabel = ({
            UILabel *l = [[UILabel alloc] init];
            l.font = [OBATheme bodyFont];
            l.textAlignment = NSTextAlignmentRight;
            [l setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            l;
        });

        if (kUseDebugColors) {
            self.backgroundColor = [UIColor purpleColor];
            _routeLabel.backgroundColor = [UIColor greenColor];
            _minutesLabel.backgroundColor = [UIColor magentaColor];
        }

        UIStackView *horizontalStack = ({
            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_routeLabel, _minutesLabel]];
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

    // TODO: clean me up once we've verified that users aren't losing their minds over the change.
    NSString *firstLineText = [NSString stringWithFormat:NSLocalizedString(@"%@ to %@\r\n", @"Route formatting string. e.g. 10 to Downtown Seattle<NEWLINE>"), [self classicDepartureRow].routeName, [self classicDepartureRow].destination];

    NSMutableAttributedString *routeText = [[NSMutableAttributedString alloc] initWithString:firstLineText attributes:@{NSFontAttributeName: [OBATheme bodyFont]}];

    [routeText addAttribute:NSFontAttributeName value:[OBATheme boldBodyFont] range:NSMakeRange(0, [self classicDepartureRow].routeName.length)];

    NSAttributedString *departureTime = [OBADepartureCellHelpers attributedDepartureTime:[self classicDepartureRow].formattedNextDepartureTime
                                                                              statusText:[self classicDepartureRow].statusText
                                                                         departureStatus:[self classicDepartureRow].departureStatus];

    [routeText appendAttributedString:departureTime];

    self.routeLabel.attributedText = routeText;

    self.minutesLabel.text = [self classicDepartureRow].formattedMinutesUntilNextDeparture;
    self.minutesLabel.textColor = [OBADepartureCellHelpers colorForStatus:[self classicDepartureRow].departureStatus];
}
@end

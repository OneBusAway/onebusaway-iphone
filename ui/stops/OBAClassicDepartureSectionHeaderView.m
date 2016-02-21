//
//  OBAClassicDepartureSectionHeaderView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicDepartureSectionHeaderView.h"

@implementation OBAClassicDepartureSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [OBATheme nonOpaquePrimaryColor];

        UILabel *routeLabel = [[UILabel alloc] init];
        routeLabel.font = [OBATheme bodyFont];
        routeLabel.text = NSLocalizedString(@"Route", @"");

        UILabel *destinationLabel = [[UILabel alloc] init];
        destinationLabel.font = [OBATheme bodyFont];
        destinationLabel.textAlignment = NSTextAlignmentCenter;
        destinationLabel.text = NSLocalizedString(@"Destination", @"");

        UILabel *minutesLabel = [[UILabel alloc] init];
        minutesLabel.font = [OBATheme bodyFont];
        minutesLabel.textAlignment = NSTextAlignmentRight;
        minutesLabel.text = NSLocalizedString(@"Minutes", @"");

        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[routeLabel, destinationLabel, minutesLabel]];
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.distribution = UIStackViewDistributionEqualSpacing;
        stackView.layoutMarginsRelativeArrangement = YES;
        stackView.layoutMargins = self.layoutMargins;
        stackView.frame = self.bounds;
        stackView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self addSubview:stackView];
    }
    return self;
}
@end

//
//  OBADepartureRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBADepartureRow.h>
#import <OBAKit/OBAViewModelRegistry.h>
#import <OBAKit/OBAClassicDepartureCell.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBATheme.h>

@implementation OBADepartureRow

- (instancetype)initWithAction:(nullable OBARowAction)action {
    self = [super initWithAction:action];

    if (self) {
        _displayContextButton = YES;
    }
    return self;
}

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBADepartureRow *row = [super copyWithZone:zone];

    row->_attributedTopLine = [_attributedTopLine copyWithZone:zone];
    row->_attributedMiddleLine = [_attributedMiddleLine copyWithZone:zone];
    row->_attributedBottomLine = [_attributedBottomLine copyWithZone:zone];

    row->_upcomingDepartures = [_upcomingDepartures copyWithZone:zone];
    row->_showAlertController = [_showAlertController copyWithZone:zone];
    row->_bookmarkExists = _bookmarkExists;
    row->_alarmExists = _alarmExists;
    row->_hasArrived = _hasArrived;
    row->_displayContextButton = _displayContextButton;
    
    return row;
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBAClassicDepartureCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

#pragma mark - Helpers

+ (NSAttributedString*)buildAttributedRoute:(NSString*)route destination:(NSString*)destination {
    NSString *lineText = nil;

    if (destination.length > 0) {
        lineText = [NSString stringWithFormat:OBALocalized(@"text_route_to_orientation_newline_params", @"Route formatting string. e.g. 10 to Downtown Seattle"), route, destination];
    }
    else {
        lineText = route;
    }

    NSMutableAttributedString *routeText = [[NSMutableAttributedString alloc] initWithString:lineText attributes:@{NSFontAttributeName: OBATheme.bodyFont}];

    [routeText addAttribute:NSFontAttributeName value:OBATheme.boldBodyFont range:NSMakeRange(0, route.length)];
    return routeText;
}

@end

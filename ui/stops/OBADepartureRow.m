//
//  OBADepartureRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBADepartureRow.h"
#import "OBAViewModelRegistry.h"
#import "OBAClassicDepartureCell.h"

@implementation OBADepartureRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBADepartureRow *row = [super copyWithZone:zone];
    row->_destination = [_destination copyWithZone:zone];
    row->_upcomingDepartures = [_upcomingDepartures copyWithZone:zone];
    row->_statusText = [_statusText copyWithZone:zone];
    row->_departureStatus = _departureStatus;
    row->_routeName = [_routeName copyWithZone:zone];

    return row;
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBAClassicDepartureCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

#pragma mark - Public

- (nullable NSString *)formattedNextDepartureTime {
    if (self.upcomingDepartures.count == 0) {
        return nil;
    }

    return [OBADateHelpers formatShortTimeNoDate:self.upcomingDepartures[0]];
}

@end

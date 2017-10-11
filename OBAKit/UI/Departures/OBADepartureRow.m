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

@implementation OBADepartureRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBADepartureRow *row = [super copyWithZone:zone];
    row->_destination = [_destination copyWithZone:zone];
    row->_upcomingDepartures = [_upcomingDepartures copyWithZone:zone];
    row->_statusText = [_statusText copyWithZone:zone];
    row->_routeName = [_routeName copyWithZone:zone];
    row->_showAlertController = [_showAlertController copyWithZone:zone];
    row->_bookmarkExists = _bookmarkExists;
    row->_alarmExists = _alarmExists;
    row->_hasArrived = _hasArrived;

    return row;
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBAClassicDepartureCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

@end

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
    row->_routeName = [_routeName copyWithZone:zone];
    row->_toggleBookmarkAction = [_toggleBookmarkAction copyWithZone:zone];
    row->_toggleAlarmAction = [_toggleAlarmAction copyWithZone:zone];
    row->_shareAction = [_shareAction copyWithZone:zone];
    row->_bookmarkExists = _bookmarkExists;
    row->_alarmExists = _alarmExists;
    row->_alarmCanBeCreated = _alarmCanBeCreated;

    return row;
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBAClassicDepartureCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

@end

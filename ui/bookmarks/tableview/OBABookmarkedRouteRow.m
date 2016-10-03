//
//  OBABookmarkedRouteRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarkedRouteRow.h"
@import OBAKit;
#import "OBAViewModelRegistry.h"
#import "OBABookmarkedRouteCell.h"

@implementation OBABookmarkedRouteRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBABookmarkedRouteRow *row = [super copyWithZone:zone];
    row->_bookmark = [_bookmark copyWithZone:zone];
    row->_nextDeparture = _nextDeparture;
    row->_supplementaryMessage = [_supplementaryMessage copyWithZone:zone];
    row->_state = _state;

    return row;
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBABookmarkedRouteCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

@end

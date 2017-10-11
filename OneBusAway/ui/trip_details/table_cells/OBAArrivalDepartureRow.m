//
//  OBAArrivalDepartureRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalDepartureRow.h"
#import "OBAArrivalDepartureCell.h"

NSString * const OBATimelineCellReuseIdentifier = @"OBATimelineCellReuseIdentifier";

@implementation OBAArrivalDepartureRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (instancetype)initWithAction:(void (^)(OBABaseRow *row))action {
    self = [super initWithAction:action];

    if (self) {
        _routeType = OBARouteTypeBus;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBAArrivalDepartureRow *row = [super copyWithZone:zone];

    row->_closestStopToVehicle = _closestStopToVehicle;
    row->_selectedStopForRider = _selectedStopForRider;
    row->_routeType = _routeType;

    return row;
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBAArrivalDepartureCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

- (NSString*)cellReuseIdentifier {
    return OBATimelineCellReuseIdentifier;
}

+ (NSString*)cellReuseIdentifier {
    return OBATimelineCellReuseIdentifier;
}

@end

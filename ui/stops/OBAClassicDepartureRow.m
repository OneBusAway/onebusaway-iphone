//
//  OBAClassicDepartureRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicDepartureRow.h"
#import "OBAViewModelRegistry.h"
#import "OBAClassicDepartureCell.h"

@implementation OBAClassicDepartureRow

- (instancetype)initWithRouteName:(NSString*)routeName destination:(NSString*)destination departsAt:(NSDate*)departsAt statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus action:(void(^)(OBABaseRow *row))action {
    self = [super initWithDestination:destination departsAt:departsAt statusText:statusText departureStatus:departureStatus action:action];

    if (self) {
        _routeName = [routeName copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBAClassicDepartureRow *row = [super copyWithZone:zone];
    row->_routeName = [_routeName copyWithZone:zone];
    return row;
}

#pragma mark - OBABaseRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBAClassicDepartureCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

@end

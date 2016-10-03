//
//  OBADepartureRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBADepartureRow.h"
#import <DateTools/DateTools.h>
#import "OBAViewModelRegistry.h"
#import "OBADepartureCell.h"
#import "OBAClassicDepartureCell.h"

NSString * const OBAClassicDepartureCellReuseIdentifier = @"OBAClassicDepartureCellReuseIdentifier";

@implementation OBADepartureRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBADepartureRow *row = [super copyWithZone:zone];
    row->_destination = [_destination copyWithZone:zone];
    row->_departsAt = [_departsAt copyWithZone:zone];
    row->_statusText = [_statusText copyWithZone:zone];
    row->_departureStatus = _departureStatus;
    row->_routeName = [_routeName copyWithZone:zone];

    return row;
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBADepartureCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
    [tableView registerClass:[OBAClassicDepartureCell class] forCellReuseIdentifier:@"OBAClassicDepartureCellReuseIdentifier"];
}

#pragma mark - Public

- (double)minutesUntilDeparture {
    return [self.departsAt minutesFrom:[NSDate date]];
}

- (NSString *)formattedMinutesUntilNextDeparture {
    
    double minutesFrom = [self minutesUntilDeparture];

    if (fabs(minutesFrom) < 1.0) {
        return NSLocalizedString(@"NOW", @"");
    }
    else {
        return [NSString stringWithFormat:@"%.0fm", minutesFrom];
    }
}

- (NSString *)formattedNextDepartureTime {
    return [OBADateHelpers formatShortTimeNoDate:self.departsAt];
}

@end

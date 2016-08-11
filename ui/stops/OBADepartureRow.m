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

@implementation OBADepartureRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (instancetype)initWithDestination:(NSString*)destination departsAt:(NSDate*)departsAt statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus action:(void(^)(OBABaseRow *row))action {
    self = [super initWithAction:action];
    
    if (self) {
        _destination = [destination copy];
        _departsAt = [departsAt copy];
        _statusText = [statusText copy];
        _departureStatus = departureStatus;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBADepartureRow *row = [super copyWithZone:zone];
    row->_destination = [_destination copyWithZone:zone];
    row->_departsAt = [_departsAt copyWithZone:zone];
    row->_statusText = [_statusText copyWithZone:zone];
    row->_departureStatus = _departureStatus;

    return row;
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBADepartureCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
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
    
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterNoStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
    });

    return [formatter stringFromDate:self.departsAt];
}

@end

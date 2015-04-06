//
//  OBAArrivalAndDepartureWK.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/13/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAArrivalAndDepartureWK.h"

@implementation OBAArrivalAndDepartureWK

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // ignored - do not throw exception
}

- (NSArray *)dictionaryRepresentationKeys {
    return @[@"tripId", @"routeId", @"stopId"];    // keys used to define equality
}

- (NSString *)description {
    NSMutableDictionary *dictionary = [[self dictionaryRepresentation] mutableCopy];
    dictionary[@"time"] = self.time;
    return [dictionary description];
}

- (NSTimeInterval)bestTime {
    long long bestTime = self.predictedDepartureTime ? : self.predictedArrivalTime ? : self.scheduledDepartureTime ? : self.scheduledArrivalTime;
    return ((NSTimeInterval)bestTime) / 1000.0;
}

- (NSDate *)time {
    NSTimeInterval bestTime = [self bestTime];
    if (bestTime == 0) {
        return nil;
    }
    else {
        NSDate *time = [NSDate dateWithTimeIntervalSince1970:bestTime];
        return time;
    }
}

@end

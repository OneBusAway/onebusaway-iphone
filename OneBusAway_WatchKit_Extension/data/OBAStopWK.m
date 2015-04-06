//
//  OBAStopWK.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/6/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAStopWK.h"

@implementation OBAStopWK

@synthesize location = _location;
- (CLLocation *)location {
    if ((_location == nil) && (([self.lat doubleValue] != 0) || ([self.lon doubleValue] != 0))) {
        _location = [[CLLocation alloc] initWithLatitude:[self.lat doubleValue] longitude:[self.lon doubleValue]];
    }

    return _location;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // Check for "id" key and change to stopId, otherwise ignore - do not throw exception
    if ([key isEqualToString:@"id"]) {
        self.stopId = value;
    }
}

- (NSArray *)dictionaryRepresentationKeys {
    return @[@"stopId", @"name", @"detail", @"direction", @"lat", @"lon", @"routeIds"];
}

@end

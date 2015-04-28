//
//  OBARouteWK.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBARouteWK.h"

@implementation OBARouteWK

- (NSString *)name {
    return [self.shortName description] ?: [self.longName description];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // Check for "id" key and change to stopId, otherwise ignore - do not throw exception
    if ([key isEqualToString:@"id"]) {
        self.routeId = value;
    }
    else if ([key isEqualToString:@"type"]) {
        self.routeType = value;
    }
}

- (NSArray *)dictionaryRepresentationKeys {
    return @[@"routeId", @"shortName", @"longName", @"routeType"];
}

@end

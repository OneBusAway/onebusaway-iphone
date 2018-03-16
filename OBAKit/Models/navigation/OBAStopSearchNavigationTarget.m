//
//  OBAStopSearchNavigationTarget.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/22/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAStopSearchNavigationTarget.h>

@implementation OBAStopSearchNavigationTarget

+ (instancetype)targetWithStopSearchQuery:(NSString*)searchQuery {
    OBAStopSearchNavigationTarget *target = [self navigationTargetForStopIDSearch:searchQuery];
    target.stopSearchQuery = searchQuery;

    return target;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        _stopSearchQuery = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(stopSearchQuery))];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_stopSearchQuery forKey:NSStringFromSelector(@selector(stopSearchQuery))];
}

- (id)copyWithZone:(NSZone *)zone {
    OBAStopSearchNavigationTarget *target = [super copyWithZone:zone];
    target->_stopSearchQuery = [_stopSearchQuery copyWithZone:zone];

    return target;
}

@end

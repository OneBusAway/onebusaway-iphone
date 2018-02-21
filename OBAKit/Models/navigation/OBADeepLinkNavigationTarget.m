//
//  OBADeepLinkNavigationTarget.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/21/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBADeepLinkNavigationTarget.h>
#import <OBAKit/OBATripDeepLink.h>

@implementation OBADeepLinkNavigationTarget

+ (instancetype)targetWithTripDeepLink:(OBATripDeepLink*)tripDeepLink {
    OBADeepLinkNavigationTarget *target = [self navigationTarget:OBANavigationTargetTypeRecentStops];
    target.tripDeepLink = tripDeepLink;

    return target;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        _tripDeepLink = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(tripDeepLink))];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_tripDeepLink forKey:NSStringFromSelector(@selector(tripDeepLink))];
}

- (id)copyWithZone:(NSZone *)zone {
    OBADeepLinkNavigationTarget *target = [super copyWithZone:zone];
    target->_tripDeepLink = [_tripDeepLink copyWithZone:zone];

    return target;
}

@end

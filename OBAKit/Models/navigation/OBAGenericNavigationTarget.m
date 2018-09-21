//
//  OBAGenericNavigationTarget.m
//  OBAKit
//
//  Created by Aaron Brethorst on 7/6/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAGenericNavigationTarget.h>

@interface OBAGenericNavigationTarget ()
@property(nonatomic,copy,readwrite) NSString *query;
@end

@implementation OBAGenericNavigationTarget

- (instancetype)initWithQuery:(NSString*)query {
    self = [super init];

    if (self) {
        _query = [query copy];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        _query = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(query))];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_query forKey:NSStringFromSelector(@selector(query))];
}

- (id)copyWithZone:(NSZone *)zone {
    OBAGenericNavigationTarget *target = [super copyWithZone:zone];
    target->_query = [_query copyWithZone:zone];

    return target;
}

@end

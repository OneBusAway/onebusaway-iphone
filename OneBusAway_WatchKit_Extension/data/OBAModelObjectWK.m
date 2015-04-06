//
//  OBAModelObjectWK.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/10/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAModelObjectWK.h"

@implementation OBAModelObjectWK

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];

    if (self) {
        [self setValuesForKeysWithDictionary:dictionary];
    }

    return self;
}

- (NSArray *)dictionaryRepresentationKeys {
    NSAssert(NO, @"abstract method. requires override.");
    return @[];
}

- (NSDictionary *)dictionaryRepresentation {
    return [self dictionaryWithValuesForKeys:[self dictionaryRepresentationKeys]];
}

- (NSDictionary *)dictionaryWithValuesForKeys:(NSArray *)keys {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    for (NSString *key in keys) {
        id value = [self valueForKey:key];

        if (value) {
            dictionary[key] = value;
        }
    }

    return [dictionary copy];
}

- (NSString *)description {
    return [[self dictionaryRepresentation] description];
}

- (NSUInteger)hash {
    return [[self dictionaryRepresentation] hash];
}

- (BOOL)isEqual:(id)object {
    return [object isMemberOfClass:[self class]] &&
           [[self dictionaryRepresentation] isEqualToDictionary:[object dictionaryRepresentation]];
}

@end

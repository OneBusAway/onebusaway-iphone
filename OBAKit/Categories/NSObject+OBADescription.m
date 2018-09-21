//
//  NSObject+OBADescription.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/29/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/NSObject+OBADescription.h>

@implementation NSObject (OBADescription)

- (NSString*)oba_description:(NSArray<NSString*>*)keys {
    return [self oba_description:keys keyPaths:nil];
}

- (NSString*)oba_description:(NSArray<NSString*>*)keys keyPaths:(NSArray<NSString *> *)keyPaths {
    return [self oba_description:keys keyPaths:keyPaths otherValues:nil];
}

- (NSString*)oba_description:(NSArray<NSString*>*)keys keyPaths:(nullable NSArray<NSString*>*)keyPaths otherValues:(nullable NSDictionary<NSString*,NSString*>*)otherValues {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryWithValuesForKeys:keys]];

    for (NSString *keyPath in keyPaths) {
        dict[keyPath] = [self valueForKeyPath:keyPath];
    }

    if (otherValues) {
        for (NSString *key in otherValues) {
            dict[key] = otherValues[key];
        }
    }

    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, dict];
}

@end

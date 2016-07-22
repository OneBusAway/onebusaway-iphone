//
//  NSObject+OBADescription.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/29/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "NSObject+OBADescription.h"

@implementation NSObject (OBADescription)

- (NSString*)oba_description:(NSArray<NSString*>*)keys {
    return [self oba_description:keys keyPaths:nil];
}

- (NSString*)oba_description:(NSArray<NSString*>*)keys keyPaths:(NSArray<NSString *> *)keyPaths {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryWithValuesForKeys:keys]];

    for (NSString *keyPath in keyPaths) {
        dict[keyPath] = [self valueForKeyPath:keyPath];
    }

    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, dict];
}

@end

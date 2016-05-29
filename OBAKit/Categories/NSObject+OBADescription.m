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
    NSDictionary *dict = [self dictionaryWithValuesForKeys:keys];

    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, dict];
}

@end

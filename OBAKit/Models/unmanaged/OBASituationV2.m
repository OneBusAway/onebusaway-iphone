//
//  OBASituationV2.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 11/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OBASituationV2.h"


@implementation OBASituationV2

@synthesize description;

- (NSInteger)severityAsNumericValue {
    return [self.class severityToNumber:self.severity];
}

+ (NSInteger)severityToNumber:(NSString*)severity {
    static NSDictionary *severityMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        severityMap = @{
                        @"noImpact": @(-2),
                        @"undefined": @(-1),
                        @"unknown": @(0),
                        @"verySlight": @(1),
                        @"slight": @(2),
                        @"normal": @(3)
                        };
    });

    if (!severity) {
        return -1;
    }

    NSNumber *n = severityMap[severity];

    if (n) {
        return [n integerValue];
    }
    else {
        return -1;
    }
}
@end

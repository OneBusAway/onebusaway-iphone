//
//  OBASituationV2.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 11/17/10.
//  Copyright 2010 OneBusAway. All rights reserved.
//

#import <OBAKit/OBASituationV2.h>

@interface OBASituationV2 ()
@property(nonatomic,copy,readwrite) NSString *diversionPath;
@end

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

// TODO: figure out why the code has the diversion path continually
// getting overwritten and if that is desirable. It sure looks like a bug...
- (NSString*)diversionPath {
    if (!_diversionPath) {
        for (OBASituationConsequenceV2 *consequence in self.consequences) {
            if (consequence.diversionPath) {
                _diversionPath = consequence.diversionPath;
            }
        }
    }
    return _diversionPath;
}

#pragma mark - Details

- (NSString*)formattedDetails {
    NSMutableArray *parts = [[NSMutableArray alloc] init];

    if (self.description.length > 0) {
        [parts addObject:self.description];
    }

    if (self.advice.length > 0) {
        [parts addObject:self.advice];
    }

    return [parts componentsJoinedByString:@"\r\n\r\n"];
}

@end

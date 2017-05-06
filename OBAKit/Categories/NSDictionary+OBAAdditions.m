//
//  NSDictionary+OBAAdditions.m
//  OBAKit
//
//  Created by Aaron Brethorst on 1/11/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <OBAKit/NSDictionary+OBAAdditions.h>

@implementation NSDictionary (OBAAdditions)

- (NSData*)oba_toHTTPBodyData {
    NSMutableArray *parts = [[NSMutableArray alloc] init];

    for (id key in self) {
        NSString *keyString = [key description];

        [parts addObject:[NSString stringWithFormat:@"%@=%@", [keyString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], [[self[key] description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
    }
    return [[parts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
}

@end

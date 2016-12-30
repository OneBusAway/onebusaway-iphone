//
//  NSURLQueryItem+OBAAdditions.m
//  OBAKit
//
//  Created by Aaron Brethorst on 10/30/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/NSURLQueryItem+OBAAdditions.h>

@implementation NSURLQueryItem (OBAAdditions)

+ (NSDictionary*)oba_dictionaryFromQueryItems:(NSArray<NSURLQueryItem*>*)queryItems {
    if (queryItems.count == 0) {
        return @{};
    }

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

    for (NSURLQueryItem *item in queryItems) {
        if (item.value) {
            dictionary[item.name] = item.value;
        }
    }

    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end

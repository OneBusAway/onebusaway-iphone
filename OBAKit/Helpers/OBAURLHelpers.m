//
//  OBAURLHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAURLHelpers.h>

@implementation OBAURLHelpers

+ (NSURL*)normalizeURLPath:(NSString*)path relativeToBaseURL:(NSString*)baseURLString parameters:(NSDictionary*)params {
    
    if (![baseURLString hasPrefix:@"http://"] && ![baseURLString hasPrefix:@"https://"]) {
        baseURLString = [@"http://" stringByAppendingString:baseURLString];
    }

    NSURLComponents *components = [[NSURLComponents alloc] initWithString:baseURLString];

    if (components.path.length == 0) {
        components.path = @"/api";
    }
    else if (![components.path hasSuffix:@"api"] && ![components.path hasSuffix:@"api/"]) {
        components.path = [components.path stringByAppendingPathComponent:@"api"];
    }

    components.path = [(components.path ?: @"") stringByAppendingPathComponent:path];

    if (params.count > 0) {
        NSMutableArray *urlQueryItems = [[NSMutableArray alloc] init];

        for (NSString *key in params) {
            [urlQueryItems addObject:[NSURLQueryItem queryItemWithName:key value:params[key]]];
        }

        components.queryItems = urlQueryItems;
    }

    return components.URL;
}

@end

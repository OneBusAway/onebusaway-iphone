//
//  OBAURLHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAURLHelpers.h"

@implementation OBAURLHelpers

+ (NSString *)escapeStringForUrl:(NSString *)url {
    // http://stackoverflow.com/questions/8088473/url-encode-an-nsstring
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                    NULL,
                                                                                                    (CFStringRef)url,
                                                                                                    NULL,
                                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                    kCFStringEncodingUTF8 ));
    
    return encodedString;
}

+ (NSURL*)normalizeURLPath:(NSString*)path relativeToBaseURL:(NSString*)baseURLString parameters:(NSDictionary*)params {
    
    if (![baseURLString hasPrefix:@"http://"] && ![baseURLString hasPrefix:@"https://"]) {
        baseURLString = [@"http://" stringByAppendingString:baseURLString];
    }

    NSURLComponents *components = [[NSURLComponents alloc] initWithString:baseURLString];

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

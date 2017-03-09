//
//  OBADeepLinkRouter.m
//  OBAKit
//
//  Created by Aaron Brethorst on 10/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBADeepLinkRouter.h"

@interface OBADeepLinkRouter ()
@property(nonatomic,strong) NSMutableDictionary *routes;
@end

@implementation OBADeepLinkRouter

- (instancetype)init {
    self = [super init];
    if (self) {
        _routes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)routePattern:(NSString*)pattern toAction:(OBADeepLinkAction)action {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    self.routes[regex] = [action copy];
}

- (BOOL)performActionForURL:(NSURL*)URL {
    NSArray *keys = [self.routes.allKeys copy];
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    NSString *path = URLComponents.path;

    for (NSRegularExpression *regex in keys) {
        NSTextCheckingResult *result = [regex firstMatchInString:path options:(NSMatchingOptions)0 range:NSMakeRange(0, path.length)];

        if (result) {
            NSMutableArray *matchValues = [NSMutableArray new];

            for (NSUInteger i=1; i<result.numberOfRanges; i++) {
                NSString *value = [path substringWithRange:[result rangeAtIndex:i]];
                [matchValues addObject:value];
            }

            OBADeepLinkAction action = self.routes[regex];
            action([matchValues copy], URLComponents);

            return YES;
        }
    }

    return NO;
}

@end

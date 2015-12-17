/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBADataSourceConfig.h"

@interface OBADataSourceConfig ()
@property(nonatomic,copy) NSURL* baseURL;
@property(nonatomic,copy) NSDictionary* defaultArgs;
@end

@implementation OBADataSourceConfig

- (instancetype)initWithURL:(NSURL*)baseURL args:(nullable NSDictionary*)args {
    self = [super init];
    
    if (self) {
        _baseURL = baseURL;
        _defaultArgs = args;
    }
    return self;
}

- (NSURL*)constructURL:(NSString*)path withArgs:(NSDictionary*)args {
    NSMutableString *constructedURL = [NSMutableString string];
    
    if (self.baseURL) {
        [constructedURL appendString:self.baseURL.absoluteString];
    }
    
    [constructedURL appendString:path];

    NSMutableArray<NSURLQueryItem*> *queryItems = [[NSMutableArray alloc] init];

    for (NSString* key in self.defaultArgs) {
        NSURLQueryItem *item = [[NSURLQueryItem alloc] initWithName:key value:[self.defaultArgs[key] description]];
        [queryItems addObject:item];
    }

    for (NSString* key in args) {
        NSURLQueryItem *item = [[NSURLQueryItem alloc] initWithName:key value:[args[key] description]];
        [queryItems addObject:item];
    }

    NSURL *URLWithPath = [self.baseURL URLByAppendingPathComponent:path];

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:URLWithPath resolvingAgainstBaseURL:NO];

    if (queryItems.count > 0) {
        components.queryItems = queryItems;
    }

    NSURL *fullURL = components.URL;

    NSLog(@"url=%@",fullURL);
    
    return fullURL;
}

@end

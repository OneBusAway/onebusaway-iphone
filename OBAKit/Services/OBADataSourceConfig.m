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

#import <OBAKit/OBADataSourceConfig.h>
#import <OBAKit/OBAMacros.h>

@interface OBADataSourceConfig ()
@property(nonatomic,copy) NSURL* baseURL;
@property(nonatomic,copy) NSArray<NSURLQueryItem*>* defaultArgs;
@end

@implementation OBADataSourceConfig

- (instancetype)initWithURL:(NSURL*)baseURL args:(nullable NSDictionary*)args {
    self = [super init];
    
    if (self) {
        _baseURL = [baseURL copy];
        _defaultArgs = [self.class dictionaryToQueryItems:args];
    }
    return self;
}

+ (instancetype)dataSourceConfigWithBaseURL:(NSURL*)URL userID:(NSString*)userID {
    NSDictionary *obaArgs = @{ @"key":     @"org.onebusaway.iphone",
                               @"app_uid": userID,
                               @"app_ver": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                               @"version": @"2"};

    return [[OBADataSourceConfig alloc] initWithURL:URL args:obaArgs];
}

#pragma mark - Public Methods

- (NSURL*)constructURL:(NSString*)path withArgs:(NSDictionary*)args {
    NSMutableArray<NSURLQueryItem*> *queryItems = [[NSMutableArray alloc] initWithArray:self.defaultArgs];
    [queryItems addObjectsFromArray:[self.class dictionaryToQueryItems:args]];

    NSURL *URLWithPath = [self.baseURL URLByAppendingPathComponent:path];

    OBAGuard(URLWithPath) else {
        return nil;
    }

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:URLWithPath resolvingAgainstBaseURL:NO];

    // This exists to work around the issue described in
    // https://github.com/OneBusAway/onebusaway-iphone/issues/755
    components.path = [components.path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];

    components.queryItems = queryItems;

    NSURL *fullURL = components.URL;

    NSLog(@"url=%@",fullURL);
    
    return fullURL;
}

#pragma mark - Private

+ (NSArray<NSURLQueryItem*>*)dictionaryToQueryItems:(nullable NSDictionary*)dictionary {
    if (!dictionary) {
        return @[];
    }

    NSMutableArray<NSURLQueryItem*> *queryArgs = [[NSMutableArray alloc] init];

    for (NSString* key in dictionary) {
        NSURLQueryItem *item = [[NSURLQueryItem alloc] initWithName:key value:[dictionary[key] description]];
        [queryArgs addObject:item];
    }

    return [queryArgs copy];
}

@end

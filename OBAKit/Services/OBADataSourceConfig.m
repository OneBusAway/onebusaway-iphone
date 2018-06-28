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
#import <OBAKit/OBALogging.h>
#import <OBAKit/NSObject+OBADescription.h>

@interface OBADataSourceConfig ()
@property(nonatomic,copy) NSURL* baseURL;
@property(nonatomic,copy) NSString *basePath;
@property(nonatomic,copy) NSArray<NSURLQueryItem*>* defaultArgs;
@end

@implementation OBADataSourceConfig

- (instancetype)initWithBaseURL:(NSURL*)URL userID:(nullable NSString*)userID checkStatusCodeInBody:(BOOL)checkStatusCodeInBody {
    self = [super init];

    if (self) {
        _baseURL = [URL copy];
        _checkStatusCodeInBody = checkStatusCodeInBody;
        _basePath = [[NSURLComponents componentsWithURL:_baseURL resolvingAgainstBaseURL:NO] percentEncodedPath];
        _defaultArgs = [OBADataSourceConfig defaultArgsWithUserID:userID];
        _contentType = OBADataSourceContentTypeJSON;
    }
    return self;
}

+ (NSArray<NSURLQueryItem*>*)defaultArgsWithUserID:(nullable NSString*)userID {
    NSMutableArray *args = [[NSMutableArray alloc] init];

    [args addObject:[NSURLQueryItem queryItemWithName:@"key" value:@"org.onebusaway.iphone"]];

    if (userID.length > 0) {
        [args addObject:[NSURLQueryItem queryItemWithName:@"app_uid" value:userID]];
    }

    [args addObject:[NSURLQueryItem queryItemWithName:@"app_ver" value:[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]]];

    [args addObject:[NSURLQueryItem queryItemWithName:@"version" value:@"2"]];

    return [NSArray arrayWithArray:args];
}

#pragma mark - Public Methods

- (NSURL*)constructURL:(NSString*)path withArgs:(NSDictionary*)args {
    NSMutableArray<NSURLQueryItem*> *queryItems = [[NSMutableArray alloc] initWithArray:self.defaultArgs];
    [queryItems addObjectsFromArray:[self.class dictionaryToQueryItems:args]];

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self.baseURL resolvingAgainstBaseURL:NO];

    components.percentEncodedPath = [self fullPathWithPathComponent:path];
    components.queryItems = queryItems;

    NSURL *fullURL = components.URL;

    DDLogInfo(@"url=%@",fullURL);
    
    return fullURL;
}

#pragma mark - Private

- (NSString*)fullPathWithPathComponent:(NSString*)pathComponent {

    NSString *fullPath = nil;

    if (self.basePath.length > 0) {
        fullPath = [self.basePath stringByAppendingPathComponent:pathComponent];
    }
    else {
        fullPath = pathComponent;
    }

    // This exists to work around the issue described in
    // https://github.com/OneBusAway/onebusaway-iphone/issues/755
    return [fullPath stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
}

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

- (NSString*)description {
    return [self oba_description:@[@"baseURL", @"basePath", @"defaultArgs"]];
}

@end

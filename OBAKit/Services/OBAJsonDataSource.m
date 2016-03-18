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

#import "OBAJsonDataSource.h"
#import "OBALogger.h"
#import "JsonUrlFetcherImpl.h"

@interface OBAJsonDataSource ()
@property(nonatomic,strong) OBADataSourceConfig *config;
@property(nonatomic,strong) NSHashTable *openConnections;
@end

@implementation OBAJsonDataSource

- (id)initWithConfig:(OBADataSourceConfig *)config {
    if (self = [super init]) {
        _config = config;
        _openConnections = [NSHashTable weakObjectsHashTable];
    }

    return self;
}

- (void)dealloc {
    [self cancelOpenConnections];
}

- (id<OBADataSourceConnection>)requestWithPath:(NSString *)path withArgs:(NSDictionary *)args completionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress {

    NSURL *feedURL = [self.config constructURL:path withArgs:args];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:feedURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];

    JsonUrlFetcherImpl *fetcher = [[JsonUrlFetcherImpl alloc] initWithCompletionBlock:completion progressBlock:progress];
    [self.openConnections addObject:fetcher];
    [fetcher loadRequest:request];

    return fetcher;
}

- (void)cancelOpenConnections {
    for (JsonUrlFetcherImpl *fetcher in self.openConnections) {
        [fetcher cancel];
    }

    [self.openConnections removeAllObjects];
}

@end

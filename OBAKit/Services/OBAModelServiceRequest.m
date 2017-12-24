/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <OBAKit/OBAModelServiceRequest.h>

@implementation OBAModelServiceRequest

- (id)init {
    self = [super init];

    if (self) {
        self.checkCode = YES;
    }

    return self;
}

- (void)dealloc {
    [self cancel];
}

- (void)processData:(id)obj withError:(NSError*)error response:(NSHTTPURLResponse*)response completionBlock:(OBADataSourceCompletion)completion {
    if (self.checkCode && [obj respondsToSelector:@selector(valueForKey:)]) {
        NSUInteger statusCode = [[obj valueForKey:@"code"] unsignedIntegerValue];
        obj = [obj valueForKey:@"data"];

        response = [[NSHTTPURLResponse alloc] initWithURL:response.URL statusCode:statusCode HTTPVersion:nil headerFields:response.allHeaderFields];
    }

    if (_modelFactorySelector && [_modelFactory respondsToSelector:_modelFactorySelector]) {
        NSError *jsonError = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        obj = [_modelFactory performSelector:_modelFactorySelector withObject:obj withObject:jsonError];
#pragma clang diagnostic pop

        if (!error) {
            error = jsonError;
        }
    }

    completion(obj, response, error);
}

#pragma mark OBAModelServiceRequest

- (void)cancel {
    [_urlSessionTask cancel];
}

@end

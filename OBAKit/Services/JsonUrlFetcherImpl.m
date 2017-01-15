//
//  JsonUrlFetcherImpl.m
//  OneBusAwaySDK
//
//  Created by Aaron Brethorst on 12/16/15.
//  Copyright © 2015 One Bus Away. All rights reserved.
//

#import <OBAKit/JsonUrlFetcherImpl.h>

@interface JsonUrlFetcherImpl ()
@property(nonatomic,strong) NSURLSessionDataTask *task;
@end

@implementation JsonUrlFetcherImpl

- (instancetype)initWithCompletionBlock:(OBADataSourceCompletion)completion {
    self = [super init];

    if (self) {
        _completionBlock = completion;
    }

    return self;
}

- (void)loadRequest:(NSURLRequest *)request {

    self.task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        id responseObject = nil;

        if (data.length) {
            NSError *jsonError = nil;
            responseObject = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&jsonError];

            if (!responseObject && jsonError) {
                error = jsonError;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(responseObject, ((NSHTTPURLResponse*)response).statusCode, error);
        });
    }];
    
    [self.task resume];
}

- (void)cancel {
    [self.task cancel];
}

@end

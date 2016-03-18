//
//  JsonUrlFetcherImpl.h
//  OneBusAwaySDK
//
//  Created by Aaron Brethorst on 12/16/15.
//  Copyright © 2015 One Bus Away. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBADataSource.h"

@interface JsonUrlFetcherImpl : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate, OBADataSourceConnection>
@property (nonatomic, copy) OBADataSourceCompletion completionBlock;
@property (nonatomic, copy) OBADataSourceProgress progressBlock;

- (instancetype)initWithCompletionBlock:(OBADataSourceCompletion)completion progressBlock:(OBADataSourceProgress)progress;
- (void)loadRequest:(NSURLRequest *)request;
@end
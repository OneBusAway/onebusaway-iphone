//
//  JsonUrlFetcherImpl.h
//  OneBusAwaySDK
//
//  Created by Aaron Brethorst on 12/16/15.
//  Copyright © 2015 One Bus Away. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBADataSource.h>

@interface JsonUrlFetcherImpl : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate, OBADataSourceConnection>
@property (nonatomic, copy) OBADataSourceCompletion completionBlock;

- (instancetype)initWithCompletionBlock:(OBADataSourceCompletion)completion;
- (void)loadRequest:(NSURLRequest *)request;
@end

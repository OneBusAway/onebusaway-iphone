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
@property (strong, nonatomic) NSURLConnection *connection;
@property (assign, nonatomic) NSStringEncoding responseEncoding;
@property (strong, nonatomic) NSMutableData *responseData;
@property (strong, nonatomic) NSHTTPURLResponse *requestResponse;
@property (assign, nonatomic) NSInteger expectedLength;
@property (nonatomic, copy) OBADataSourceCompletion completionBlock;
@property (nonatomic, copy) OBADataSourceProgress progressBlock;
@property (nonatomic, assign) BOOL uploading;
- (void)loadRequest:(NSURLRequest *)request;
@end
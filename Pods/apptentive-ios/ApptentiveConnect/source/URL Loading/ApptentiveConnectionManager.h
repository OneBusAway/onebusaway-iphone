//
//  ApptentiveConnectionManager.h
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveURLConnection;


@interface ApptentiveConnectionManager : NSObject
+ (ApptentiveConnectionManager *)sharedSingleton;
- (void)start;
- (void)stop;
- (void)addConnection:(ApptentiveURLConnection *)connection toChannel:(NSString *)channelName;
- (void)cancelAllConnectionsInChannel:(NSString *)channelName;
- (void)cancelConnection:(ApptentiveURLConnection *)connection inChannel:(NSString *)channelName;
- (void)setMaximumActiveConnections:(NSUInteger)maximumConnections forChannel:(NSString *)channelName;
@end

//
//  ATConnectionManager.m
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveConnectionManager.h"
#import "ApptentiveConnectionChannel.h"

static ApptentiveConnectionManager *sharedSingleton = nil;

#define PLACEHOLDER_CHANNEL_NAME @"ATDefaultChannel"


@interface ApptentiveConnectionManager ()
- (ApptentiveConnectionChannel *)channelForName:(NSString *)channelName;
@end


@implementation ApptentiveConnectionManager {
	NSMutableDictionary *channels;
}

+ (ApptentiveConnectionManager *)sharedSingleton {
	@synchronized(self) {
		if (!sharedSingleton) {
			sharedSingleton = [[ApptentiveConnectionManager alloc] init];
		}
	}
	return sharedSingleton;
}

- (id)init {
	if ((self = [super init])) {
		channels = [[NSMutableDictionary alloc] init];
		return self;
	}
	return nil;
}

- (void)start {
	for (ApptentiveConnectionChannel *channel in [channels allValues]) {
		[channel update];
	}
}

- (void)stop {
	for (ApptentiveConnectionChannel *channel in [channels allValues]) {
		[channel cancelAllConnections];
	}
}

- (void)addConnection:(ApptentiveURLConnection *)connection toChannel:(NSString *)channelName {
	ApptentiveConnectionChannel *channel = [self channelForName:channelName];
	[channel addConnection:connection];
}

- (void)cancelAllConnectionsInChannel:(NSString *)channelName {
	ApptentiveConnectionChannel *channel = [self channelForName:channelName];
	[channel cancelAllConnections];
}

- (void)cancelConnection:(ApptentiveURLConnection *)connection inChannel:(NSString *)channelName {
	ApptentiveConnectionChannel *channel = [self channelForName:channelName];
	[channel cancelConnection:connection];
}

- (void)setMaximumActiveConnections:(NSUInteger)maximumConnections forChannel:(NSString *)channelName {
	ApptentiveConnectionChannel *channel = [self channelForName:channelName];
	channel.maximumConnections = maximumConnections;
}


- (ApptentiveConnectionChannel *)channelForName:(NSString *)channelName {
	if (!channelName) {
		channelName = PLACEHOLDER_CHANNEL_NAME;
	}
	ApptentiveConnectionChannel *channel = [channels objectForKey:channelName];
	if (!channel) {
		channel = [[ApptentiveConnectionChannel alloc] init];
		[channels setObject:channel forKey:channelName];
	}
	return channel;
}

- (void)dealloc {
	[self stop];
	[channels removeAllObjects];
}
@end

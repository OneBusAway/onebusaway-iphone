//
//  ATConnectionChannel.m
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveConnectionChannel.h"
#import "ApptentiveURLConnection.h"
#import "ApptentiveURLConnection_Private.h"


@interface ApptentiveConnectionChannel ()

@property (strong, nonatomic) NSMutableSet *active;
@property (strong, nonatomic) NSMutableArray *waiting;

@end


@implementation ApptentiveConnectionChannel

- (id)init {
	if ((self = [super init])) {
		_maximumConnections = 2;
		_active = [[NSMutableSet alloc] init];
		_waiting = [[NSMutableArray alloc] init];
		return self;
	}
	return nil;
}

- (void)update {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
		return;
	}

	@synchronized(self) {
		@autoreleasepool {
			while ([self.active count]<self.maximumConnections && [self.waiting count]> 0) {
				ApptentiveURLConnection *loader = [self.waiting objectAtIndex:0];
				[self.active addObject:loader];
				[loader addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];
				[self.waiting removeObjectAtIndex:0];
				[loader start];
			}
		}
	}
}

- (void)addConnection:(ApptentiveURLConnection *)connection {
	@synchronized(self) {
		[self.waiting addObject:connection];
		[self update];
	}
}

- (void)cancelAllConnections {
	@synchronized(self) {
		for (ApptentiveURLConnection *loader in self.active) {
			[loader removeObserver:self forKeyPath:@"isFinished"];
			[loader cancel];
		}
		[self.active removeAllObjects];
		for (ApptentiveURLConnection *loader in self.waiting) {
			[loader cancel];
		}
		[self.waiting removeAllObjects];
	}
}

- (void)cancelConnection:(ApptentiveURLConnection *)connection {
	@synchronized(self) {
		if ([self.active containsObject:connection]) {
			[connection removeObserver:self forKeyPath:@"isFinished"];
			[connection cancel];
			[self.active removeObject:connection];
		}

		if ([self.waiting containsObject:connection]) {
			[connection cancel];
			[self.waiting removeObject:connection];
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqual:@"isFinished"] && [(ApptentiveURLConnection *)object isFinished]) {
		@synchronized(self) {
			[object removeObserver:self forKeyPath:@"isFinished"];
			[self.active removeObject:object];
		}
		[self update];
	}
}

- (void)dealloc {
	[self cancelAllConnections];
}
@end

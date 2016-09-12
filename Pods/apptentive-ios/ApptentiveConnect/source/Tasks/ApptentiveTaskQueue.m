//
//  ApptentiveTaskQueue.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/21/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveTaskQueue.h"
#import "ApptentiveBackend.h"
#import "ApptentiveTask.h"
#import "ApptentiveLegacyRecord.h"
#import "Apptentive_Private.h"

#define kATTaskQueueCodingVersion 1
// Retry period in seconds.
#define kATTaskQueueRetryPeriod 180.0

#define kMaxFailureCount 30

static ApptentiveTaskQueue *sharedTaskQueue = nil;


@interface ApptentiveTaskQueue ()
- (void)setup;
- (void)teardown;
- (void)archive;
- (void)unsetActiveTask;
@end


@implementation ApptentiveTaskQueue {
	ApptentiveTask *activeTask;
	NSMutableArray *tasks;
}

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATTaskQueue"];
}

+ (NSString *)taskQueuePath {
	return [[[Apptentive sharedConnection].backend supportDirectoryPath] stringByAppendingPathComponent:@"tasks.objects"];
}

+ (BOOL)serializedQueueExists {
	NSFileManager *fm = [NSFileManager defaultManager];
	return [fm fileExistsAtPath:[ApptentiveTaskQueue taskQueuePath]];
}


+ (ApptentiveTaskQueue *)sharedTaskQueue {
	@synchronized(self) {
		if (sharedTaskQueue == nil) {
			if ([ApptentiveTaskQueue serializedQueueExists]) {
				NSError *error = nil;
				NSData *data = [NSData dataWithContentsOfFile:[ApptentiveTaskQueue taskQueuePath] options:NSDataReadingMapped error:&error];
				if (!data) {
					ApptentiveLogError(@"Unable to unarchive task queue: %@", error);
				} else {
					@try {
						NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
						[unarchiver setClass:[ApptentiveLegacyRecord class] forClassName:@"ATRecord"];
						sharedTaskQueue = [unarchiver decodeObjectForKey:@"root"];
						unarchiver = nil;
					} @catch (NSException *exception) {
						ApptentiveLogError(@"Unable to unarchive task queue: %@", exception);
					}
				}
			}
			if (!sharedTaskQueue) {
				sharedTaskQueue = [[ApptentiveTaskQueue alloc] init];
			}
		}
	}
	return sharedTaskQueue;
}

+ (void)releaseSharedTaskQueue {
	@synchronized(self) {
		if (sharedTaskQueue != nil) {
			[sharedTaskQueue archive];
			sharedTaskQueue = nil;
		}
	}
}

- (id)init {
	if ((self = [super init])) {
		[self setup];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATTaskQueueCodingVersion) {
			tasks = [coder decodeObjectForKey:@"tasks"];
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATTaskQueueCodingVersion forKey:@"version"];
	@synchronized(self) {
		NSMutableArray *archivableTasks = [[NSMutableArray alloc] init];
		for (ApptentiveTask *task in tasks) {
			if ([task shouldArchive]) {
				[archivableTasks addObject:task];
			}
		}
		[coder encodeObject:archivableTasks forKey:@"tasks"];
		archivableTasks = nil;
	}
}

- (void)dealloc {
	[self teardown];
}


- (void)addTask:(ApptentiveTask *)task {
	@synchronized(self) {
		[tasks addObject:task];
		[self archive];
	}
	[self start];
}

- (BOOL)hasTaskOfClass:(Class)c {
	BOOL result = NO;
	@synchronized(self) {
		for (ApptentiveTask *task in tasks) {
			if ([task isKindOfClass:c]) {
				result = YES;
				break;
			}
		}
	}
	return result;
}

- (void)removeTasksOfClass:(Class)c {
	@synchronized(self) {
		NSArray *taskSnapshot = [tasks copy];
		for (ApptentiveTask *task in taskSnapshot) {
			if ([task isKindOfClass:c]) {
				[task stop];
				[tasks removeObject:task];
			}
		}
	}
}

- (NSUInteger)count {
	NSUInteger count = 0;
	@synchronized(self) {
		count = [tasks count];
	}
	return count;
}

- (ApptentiveTask *)taskAtIndex:(NSUInteger)index {
	@synchronized(self) {
		return [tasks objectAtIndex:index];
	}
}

- (NSUInteger)countOfTasksWithTaskNamesInSet:(NSSet *)taskNames {
	NSUInteger count = 0;
	@synchronized(self) {
		for (ApptentiveTask *task in tasks) {
			if ([taskNames containsObject:[task taskName]]) {
				count++;
			}
		}
	}
	return count;
}

- (ApptentiveTask *)taskAtIndex:(NSUInteger)index withTaskNameInSet:(NSSet *)taskNames {
	NSMutableArray *accum = [NSMutableArray array];
	@synchronized(self) {
		for (ApptentiveTask *task in tasks) {
			if ([taskNames containsObject:[task taskName]]) {
				[accum addObject:task];
			}
		}
	}
	if (index < [accum count]) {
		return [accum objectAtIndex:index];
	}
	return nil;
}

- (void)start {
	// We can no longer do this in the background because of CoreData objects.
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
		return;
	}
	@autoreleasepool {
		@synchronized(self) {
			if (activeTask) {
				return;
			}

			if ([tasks count]) {
				for (ApptentiveTask *task in tasks) {
					if ([task canStart]) {
						activeTask = task;
						[activeTask addObserver:self forKeyPath:@"finished" options:NSKeyValueObservingOptionNew context:NULL];
						[activeTask addObserver:self forKeyPath:@"failed" options:NSKeyValueObservingOptionNew context:NULL];
						[activeTask start];
						break;
					}
				}
			}
		}
	}
}

- (void)stop {
	@synchronized(self) {
		[activeTask stop];
		[self unsetActiveTask];
	}
}

- (NSString *)queueDescription {
	NSMutableString *result = [[NSMutableString alloc] init];
	@synchronized(self) {
		[result appendString:[NSString stringWithFormat:@"<ATTaskQueue: %lu task(s) [", (unsigned long)[tasks count]]];
		NSMutableArray *parts = [[NSMutableArray alloc] init];
		for (ApptentiveTask *task in tasks) {
			[parts addObject:[task taskDescription]];
		}
		if ([parts count]) {
			[result appendString:@"\n"];
			[result appendString:[parts componentsJoinedByString:@",\n"]];
			[result appendString:@"\n"];
		}
		parts = nil;
		[result appendString:@"]>"];
	}
	return result;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	@synchronized(self) {
		if (object != activeTask) return;
		ApptentiveTask *task = (ApptentiveTask *)object;

		if (![task isKindOfClass:[ApptentiveTask class]]) {
			ApptentiveLogError(@"Object was not subclass of ATTask");
			return;
		}

		if ([keyPath isEqualToString:@"finished"] && [task finished]) {
			[self unsetActiveTask];
			[task cleanup];
			[tasks removeObject:object];
			[self archive];
			[self startOnNextRunLoopIteration];
		} else if ([keyPath isEqualToString:@"failed"] && [task failed]) {
			if (task.shouldRetry) {
				[self stop];
				task.failureCount = task.failureCount + 1;
				if (task.failureCount > kMaxFailureCount) {
					ApptentiveLogError(@"Task %@ failed too many times, removing from queue.", task);
					[self unsetActiveTask];
					[task cleanup];
					[tasks removeObject:task];
					[self archive];
					[self startOnNextRunLoopIteration];
				} else {
					// Retry it
					[self performSelector:@selector(start) withObject:nil afterDelay:kATTaskQueueRetryPeriod];
				}
			} else {
				[self unsetActiveTask];
				[task cleanup];
				[tasks removeObject:task];
				[self archive];
				[self startOnNextRunLoopIteration];
			}
		}
	}
}

- (void)startOnNextRunLoopIteration {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self start];
	});
}

#pragma mark - Private methods

- (void)setup {
	@synchronized(self) {
		tasks = [[NSMutableArray alloc] init];
	}
}

- (void)teardown {
	@synchronized(self) {
		[self stop];
		tasks = nil;
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}
}

- (void)unsetActiveTask {
	@synchronized(self) {
		if (activeTask) {
			[activeTask removeObserver:self forKeyPath:@"finished"];
			[activeTask removeObserver:self forKeyPath:@"failed"];
			activeTask = nil;
		}
	}
}

- (void)archive {
	@synchronized(self) {
		if ([ApptentiveTaskQueue taskQueuePath]) {
			if (![NSKeyedArchiver archiveRootObject:sharedTaskQueue toFile:[ApptentiveTaskQueue taskQueuePath]]) {
				ApptentiveLogError(@"Unable to archive task queue to: %@", [ApptentiveTaskQueue taskQueuePath]);
			}
		}
	}
}
@end

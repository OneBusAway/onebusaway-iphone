//
//  ApptentiveTaskQueue.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/21/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveTask;


@interface ApptentiveTaskQueue : NSObject <NSCoding>
+ (NSString *)taskQueuePath;
+ (BOOL)serializedQueueExists;
+ (ApptentiveTaskQueue *)sharedTaskQueue;
+ (void)releaseSharedTaskQueue;

- (void)addTask:(ApptentiveTask *)task;
- (BOOL)hasTaskOfClass:(Class)c;
- (void)removeTasksOfClass:(Class)c;
- (NSUInteger)count;
- (ApptentiveTask *)taskAtIndex:(NSUInteger)index;
- (NSUInteger)countOfTasksWithTaskNamesInSet:(NSSet *)taskNames;
- (ApptentiveTask *)taskAtIndex:(NSUInteger)index withTaskNameInSet:(NSSet *)taskNames;
- (void)start;
- (void)stop;

- (NSString *)queueDescription;
@end

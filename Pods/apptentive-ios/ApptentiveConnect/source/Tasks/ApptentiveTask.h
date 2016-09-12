//
//  ApptentiveTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ApptentiveTask : NSObject <NSCoding>
@property (assign, nonatomic) BOOL inProgress;
@property (assign, nonatomic) BOOL finished;
@property (assign, nonatomic) BOOL failed;
@property (assign, nonatomic) NSUInteger failureCount;

@property (copy, nonatomic) NSString *lastErrorTitle;
@property (copy, nonatomic) NSString *lastErrorMessage;
@property (assign, nonatomic) BOOL shouldRetry;


- (BOOL)canStart;
- (BOOL)shouldArchive;
- (void)start;
- (void)stop;
/*! Called before we delete this task. */
- (void)cleanup;
- (float)percentComplete;
- (NSString *)taskName;

- (NSString *)taskDescription;
@end

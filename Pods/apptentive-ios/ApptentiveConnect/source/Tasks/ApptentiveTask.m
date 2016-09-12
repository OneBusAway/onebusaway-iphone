//
//  ApptentiveTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveTask.h"

#define kATTaskCodingVersion 2


@implementation ApptentiveTask

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATTask"];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		_failureCount = 0;
		_shouldRetry = YES;
		if (version >= 2) {
			self.failureCount = [(NSNumber *)[coder decodeObjectForKey:@"failureCount"] unsignedIntegerValue];
		} else {
			return nil;
		}
	}
	return self;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_shouldRetry = YES;
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATTaskCodingVersion forKey:@"version"];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:self.failureCount] forKey:@"failureCount"];
}

- (BOOL)canStart {
	return YES;
}

- (BOOL)shouldArchive {
	return YES;
}

- (void)start {
}

- (void)stop {
}

- (float)percentComplete {
	return 0.0f;
}

- (NSString *)taskName {
	return @"task";
}

- (void)cleanup {
	// Do nothing by default.
}

- (NSString *)taskDescription {
	NSMutableArray *parts = [[NSMutableArray alloc] init];
	if (self.lastErrorTitle) {
		[parts addObject:[NSString stringWithFormat:@"lastErrorTitle: %@", self.lastErrorTitle]];
	}
	if (self.lastErrorMessage) {
		[parts addObject:[NSString stringWithFormat:@"lastErrorMessage: %@", self.lastErrorMessage]];
	}
	[parts addObject:[NSString stringWithFormat:@"inProgress: %@", self.inProgress ? @"YES" : @"NO"]];
	[parts addObject:[NSString stringWithFormat:@"finished: %@", self.finished ? @"YES" : @"NO"]];
	[parts addObject:[NSString stringWithFormat:@"failed: %@", self.failed ? @"YES" : @"NO"]];
	[parts addObject:[NSString stringWithFormat:@"failureCount: %lu", (unsigned long)self.failureCount]];
	[parts addObject:[NSString stringWithFormat:@"percentComplete: %f", [self percentComplete]]];
	[parts addObject:[NSString stringWithFormat:@"taskName: %@", [self taskName]]];

	NSString *d = [parts componentsJoinedByString:@", "];
	parts = nil;
	return [NSString stringWithFormat:@"<%@ %p: %@>", NSStringFromClass([self class]), self, d];
}
@end

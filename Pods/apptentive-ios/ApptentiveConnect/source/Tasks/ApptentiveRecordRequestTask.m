//
//  ApptentiveRecordRequestTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/10/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecordRequestTask.h"
#import "ApptentiveData.h"
#import "Apptentive_Private.h"
#import "ApptentiveEvent.h"
#import "ApptentiveWebClient+Metrics.h"
#import "ApptentiveConversationUpdater.h"

#define kATRecordRequestTaskCodingVersion 2


@interface ApptentiveRecordRequestTask ()

@property (strong, nonatomic) ApptentiveAPIRequest *request;

@end


@implementation ApptentiveRecordRequestTask

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATRecordRequestTask"];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATRecordRequestTaskCodingVersion) {
			NSString *pendingEventID = [coder decodeObjectForKey:@"pendingEventID"];
			_event = [ApptentiveEvent findEventWithPendingID:pendingEventID];
			if (_event == nil) {
				ApptentiveLogError(@"Event can't be found in CoreData");
				self.finished = YES;
			}
		} else if (version == 1) {
			NSURL *providerURI = [coder decodeObjectForKey:@"managedObjectURIRepresentation"];
			NSManagedObject *obj = [ApptentiveData findEntityWithURI:providerURI];
			if (obj == nil) {
				ApptentiveLogError(@"Unarchived task can't be found in CoreData");
				self.finished = YES;
			} else if ([obj isKindOfClass:[ApptentiveEvent class]]) {
				_event = (ApptentiveEvent *)obj;
			} else {
				ApptentiveLogError(@"Unarchived task isn't an ApptentiveEvent instance.");
				return nil;
			}
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATRecordRequestTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.event.pendingEventID forKey:@"pendingEventID"];
}

- (void)dealloc {
	[self stop];
}

- (BOOL)canStart {
	if ([Apptentive sharedConnection].webClient == nil) {
		return NO;
	}
	if (![ApptentiveConversationUpdater conversationExists]) {
		return NO;
	}
	return YES;
}

- (void)start {
	if (!self.request) {
		self.request = [[Apptentive sharedConnection].webClient requestForSendingEvent:self.event];
		if (self.request != nil) {
			self.request.delegate = self;
			[self.request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
	}
}

- (void)stop {
	if (self.request) {
		self.request.delegate = nil;
		[self.request cancel];
		self.request = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (self.request) {
		return [self.request percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"request";
}

- (void)cleanup {
	[self.event cleanupAfterTask:self];
}

#pragma mark ApptentiveAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)sender result:(id)result {
	@synchronized(self) {
		ATRecordRequestTaskResult taskResult = [self.event taskResultForTask:self withRequest:sender withResult:result];
		switch (taskResult) {
			case ATRecordRequestTaskFailedResult:
				self.failed = YES;
				break;
			case ATRecordRequestTaskFinishedResult:
				self.finished = YES;
				break;
		}
		[self stop];
	}
}

- (void)at_APIRequestDidProgress:(ApptentiveAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)sender {
	@synchronized(self) {
		self.failed = YES;
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;
		ApptentiveLogInfo(@"ApptentiveAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		[self stop];
	}
}
@end

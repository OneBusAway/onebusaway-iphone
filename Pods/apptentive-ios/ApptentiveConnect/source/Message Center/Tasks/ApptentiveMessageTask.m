//
//  ApptentiveMessageTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageTask.h"
#import "ApptentiveBackend.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveLog.h"
#import "ApptentiveMessage.h"
#import "ApptentiveConversationUpdater.h"
#import "Apptentive_Private.h"
#import "ApptentiveWebClient.h"
#import "ApptentiveWebClient+MessageCenter.h"

#define kATMessageTaskCodingVersion 2


@interface ApptentiveMessageTask ()
- (BOOL)processResult:(NSDictionary *)jsonMessage;
@end


@implementation ApptentiveMessageTask {
	ApptentiveAPIRequest *request;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATMessageTaskCodingVersion) {
			self.pendingMessageID = [coder decodeObjectForKey:@"pendingMessageID"];
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATMessageTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.pendingMessageID forKey:@"pendingMessageID"];
}

- (void)dealloc {
	[self stop];
}

- (BOOL)canStart {
	if ([Apptentive sharedConnection].webClient == nil) {
		ApptentiveLogError(@"Failed to send message because Apptentive API key is not set!");
		return NO;
	}
	if (![ApptentiveConversationUpdater conversationExists]) {
		return NO;
	}
	if ([[Apptentive sharedConnection].backend isUpdatingPerson]) {
		// Don't send until the person is done being updated.
		return NO;
	}
	return YES;
}

- (void)start {
	if (!request) {
		ApptentiveMessage *message = [ApptentiveMessage findMessageWithPendingID:self.pendingMessageID];
		if (message == nil) {
			ApptentiveLogError(@"Warning: Message was nil in message task.");
			self.finished = YES;
			return;
		}
		request = [[Apptentive sharedConnection].webClient requestForPostingMessage:message];
		if (request != nil) {
			[[Apptentive sharedConnection].backend messageTaskDidBegin:self];

			request.delegate = self;
			[request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
		message = nil;
	}
}

- (void)stop {
	if (request) {
		request.delegate = nil;
		[request cancel];
		request = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"message";
}

- (NSUInteger)hash {
	return self.pendingMessageID.hash;
}

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]]) {
		return NO;
	} else if (self == object) {
		return YES;
	} else {
		return [self.pendingMessageID isEqualToString:((ApptentiveMessageTask *)object).pendingMessageID];
	}
}

#pragma mark ApptentiveAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		[[Apptentive sharedConnection].backend messageTaskDidFinish:self];

		if ([result isKindOfClass:[NSDictionary class]] && [self processResult:(NSDictionary *)result]) {
			self.finished = YES;
		} else {
			ApptentiveLogError(@"Message result is not NSDictionary!");
			self.failed = YES;
		}
		[self stop];
	}
}

- (void)at_APIRequestDidProgress:(ApptentiveAPIRequest *)sender {
	[[Apptentive sharedConnection].backend messageTask:self didProgress:self.percentComplete];
}

- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)sender {
	@synchronized(self) {
		[[Apptentive sharedConnection].backend messageTaskDidFail:self];
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;

		ApptentiveMessage *message = [ApptentiveMessage findMessageWithPendingID:self.pendingMessageID];
		if (message == nil) {
			ApptentiveLogError(@"Warning: Message went away during task.");
			self.finished = YES;
			return;
		}
		[message setErrorOccurred:@(YES)];
		if (sender.errorResponse != nil) {
			NSError *parseError = nil;
			NSObject *errorObject = [ApptentiveJSONSerialization JSONObjectWithString:sender.errorResponse error:&parseError];
			if (errorObject != nil && [errorObject isKindOfClass:[NSDictionary class]]) {
				NSDictionary *errorDictionary = (NSDictionary *)errorObject;
				if ([errorDictionary objectForKey:@"errors"]) {
					ApptentiveLogInfo(@"ApptentiveAPIRequest server error: %@", [errorDictionary objectForKey:@"errors"]);
					[message setErrorMessageJSON:sender.errorResponse];
				}
			} else if (errorObject == nil) {
				ApptentiveLogError(@"Error decoding error response: %@", parseError);
			}
			[message setPendingState:@(ATPendingMessageStateError)];
		}
		NSError *error = nil;
		NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
		if (![context save:&error]) {
			ApptentiveLogError(@"Failed to save message after API failure: %@", error);
		}
		ApptentiveLogInfo(@"ApptentiveAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		if (self.failureCount > 2) {
			self.finished = YES;
		} else {
			self.failed = YES;
		}
		[self stop];
		message = nil;
	}
}

#pragma mark - Private methods

- (BOOL)processResult:(NSDictionary *)jsonMessage {
	ApptentiveLogDebug(@"getting json result: %@", jsonMessage);
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];

	ApptentiveMessage *message = [ApptentiveMessage findMessageWithPendingID:self.pendingMessageID];
	if (message == nil) {
		ApptentiveLogError(@"Warning: Message went away during task.");
		return YES;
	}
	[message updateWithJSON:jsonMessage];
	message.pendingState = [NSNumber numberWithInt:ATPendingMessageStateConfirmed];

	NSError *error = nil;
	if (![context save:&error]) {
		ApptentiveLogError(@"Failed to save new message: %@", error);
		message = nil;
		return NO;
	}
	message = nil;
	return YES;
}
@end

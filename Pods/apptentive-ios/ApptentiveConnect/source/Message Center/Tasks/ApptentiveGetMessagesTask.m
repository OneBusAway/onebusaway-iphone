//
//  ApptentiveGetMessagesTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/12/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveGetMessagesTask.h"

#import "ApptentiveBackend.h"
#import "ApptentiveMessage.h"
#import "ApptentiveConversationUpdater.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveWebClient.h"
#import "ApptentiveWebClient+MessageCenter.h"
#import "NSDictionary+Apptentive.h"
#import "Apptentive_Private.h"

static NSString *const ATMessagesLastRetrievedMessageIDPreferenceKey = @"ATMessagesLastRetrievedMessagIDPreferenceKey";


@interface ApptentiveGetMessagesTask ()
- (BOOL)processResult:(NSDictionary *)jsonMessage;
@end


@implementation ApptentiveGetMessagesTask {
	ApptentiveAPIRequest *request;
	ApptentiveMessage *lastMessage;
}

- (id)init {
	if ((self = [super init])) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *messageID = [defaults objectForKey:ATMessagesLastRetrievedMessageIDPreferenceKey];
		if (messageID) {
			lastMessage = [ApptentiveMessage findMessageWithID:messageID];
		}
	}
	return self;
}

- (void)dealloc {
	[self stop];
}

- (BOOL)shouldArchive {
	return NO;
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
	if (!request) {
		request = [[Apptentive sharedConnection].webClient requestForRetrievingMessagesSinceMessage:lastMessage];
		if (request != nil) {
			request.delegate = self;
			[request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
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
	return @"getmessages";
}

#pragma mark ApptentiveAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		UIBackgroundFetchResult fetchResult;

		if ([result isKindOfClass:[NSDictionary class]] && [self processResult:(NSDictionary *)result]) {
			self.finished = YES;
			fetchResult = UIBackgroundFetchResultNewData;
		} else {
			ApptentiveLogError(@"Could not process the Get Message Task result!");
			self.failed = YES;
			fetchResult = UIBackgroundFetchResultFailed;
		}
		[self stop];

		[[Apptentive sharedConnection].backend completeMessageFetchWithResult:fetchResult];
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

#pragma mark - Private methods

- (BOOL)processResult:(NSDictionary *)jsonMessages {
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
	NSString *lastMessageID = nil;

	ApptentiveConversation *conversation = [ApptentiveConversationUpdater currentConversation];

	do { // once
		if (!jsonMessages) break;
		if (![jsonMessages at_safeObjectForKey:@"items"]) break;

		NSArray *messages = [jsonMessages at_safeObjectForKey:@"items"];
		if (![messages isKindOfClass:[NSArray class]]) break;
		if (messages.count > 0) {
			ApptentiveLogDebug(@"Apptentive messages: %@", jsonMessages);
		}

		BOOL success = YES;
		for (NSDictionary *messageJSON in messages) {
			NSString *pendingMessageID = [messageJSON at_safeObjectForKey:@"nonce"];
			NSString *messageID = [messageJSON at_safeObjectForKey:@"id"];
			ApptentiveMessage *message = nil;
			message = [ApptentiveMessage findMessageWithPendingID:pendingMessageID];
			if (!message) {
				message = [ApptentiveMessage findMessageWithID:messageID];
			}
			if (!message) {
				message = (ApptentiveMessage *)[ApptentiveMessage newInstanceWithJSON:messageJSON];
				if (conversation && [conversation.personID isEqualToString:message.sender.apptentiveID]) {
					message.sentByUser = @(YES);
					message.seenByUser = @(YES);
				}
				message.pendingState = @(ATPendingMessageStateConfirmed);
				if (message) {
					lastMessageID = messageID;
				}
			} else {
				lastMessageID = messageID;
				[message updateWithJSON:messageJSON];
			}
			if (!message) {
				success = NO;
				break;
			}
		}
		NSError *error = nil;
		if (![context save:&error]) {
			ApptentiveLogError(@"Failed to save messages: %@", error);
			success = NO;
		}
		if (success && lastMessageID) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject:lastMessageID forKey:ATMessagesLastRetrievedMessageIDPreferenceKey];
			[defaults synchronize];
		}
		return YES;
	} while (NO);
	return NO;
}
@end

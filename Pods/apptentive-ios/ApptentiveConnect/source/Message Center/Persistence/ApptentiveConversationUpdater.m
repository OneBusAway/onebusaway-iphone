//
//  ApptentiveConversationUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationUpdater.h"

#import "ApptentiveBackend.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveWebClient+MessageCenter.h"
#import "Apptentive_Private.h"

NSString *const ATCurrentConversationPreferenceKey = @"ATCurrentConversationPreferenceKey";

NSString *const ATConversationLastUpdatePreferenceKey = @"ATConversationLastUpdatePreferenceKey";
NSString *const ATConversationLastUpdateValuePreferenceKey = @"ATConversationLastUpdateValuePreferenceKey";


@interface ApptentiveConversationUpdater ()
- (void)processResult:(NSDictionary *)jsonActivityFeed;
@end


@implementation ApptentiveConversationUpdater {
	ApptentiveAPIRequest *request;
	BOOL creatingConversation;
}

+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences =
		[NSDictionary dictionaryWithObjectsAndKeys:
						  [NSDate distantPast], ATConversationLastUpdatePreferenceKey,
					  [NSDictionary dictionary], ATConversationLastUpdateValuePreferenceKey,
					  nil];
	[defaults registerDefaults:defaultPreferences];
}

- (id)initWithDelegate:(NSObject<ApptentiveConversationUpdaterDelegate> *)delegate {
	if ((self = [super init])) {
		_delegate = delegate;
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	[self cancel];
}

- (void)createOrUpdateConversation {
	[self cancel];

	ApptentiveConversation *currentConversation = [ApptentiveConversationUpdater currentConversation];
	if (currentConversation == nil) {
		ApptentiveLogDebug(@"Creating conversation");
		creatingConversation = YES;
		ApptentiveConversation *conversation = [[ApptentiveConversation alloc] init];
		conversation.deviceID = [[Apptentive sharedConnection].backend deviceUUID];
		request = [[Apptentive sharedConnection].webClient requestForCreatingConversation:conversation];
		request.delegate = self;
		[request start];
		conversation = nil;
	} else {
		creatingConversation = NO;
		request = [[Apptentive sharedConnection].webClient requestForUpdatingConversation:currentConversation];
		request.delegate = self;
		[request start];
	}
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		request = nil;
	}
}

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

+ (BOOL)conversationExists {
	ApptentiveConversation *currentFeed = [ApptentiveConversationUpdater currentConversation];
	if (currentFeed == nil) {
		return NO;
	} else {
		return YES;
	}
}

+ (ApptentiveConversation *)currentConversation {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *conversationData = [defaults dataForKey:ATCurrentConversationPreferenceKey];
	if (!conversationData) {
		return nil;
	}
	ApptentiveConversation *conversation = nil;
	@try {
		conversation = [NSKeyedUnarchiver unarchiveObjectWithData:conversationData];
	} @catch (NSException *exception) {
		ApptentiveLogError(@"Unable to unarchive conversation: %@", exception);
	}
	return conversation;
}

+ (BOOL)shouldUpdate {
	[ApptentiveConversationUpdater registerDefaults];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSObject *lastValue = [defaults objectForKey:ATConversationLastUpdateValuePreferenceKey];
	BOOL shouldUpdate = YES;

	do { // once
		if (lastValue == nil || ![lastValue isKindOfClass:[NSDictionary class]]) {
			break;
		}
		NSDictionary *lastValueDictionary = (NSDictionary *)lastValue;
		ApptentiveConversation *conversation = [self currentConversation];
		if (!conversation) {
			break;
		}
		NSDictionary *currentValueDictionary = [conversation apiUpdateJSON];
		if (![ApptentiveUtilities dictionary:currentValueDictionary isEqualToDictionary:lastValueDictionary]) {
			break;
		}
		shouldUpdate = NO;
	} while (NO);

	return shouldUpdate;
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			if (creatingConversation) {
				ApptentiveLogError(@"Activity feed result is not NSDictionary!");
				[self.delegate conversationUpdater:self createdConversationSuccessfully:NO];
			} else {
				// Empty response is expected for conversation update.
				[self.delegate conversationUpdater:self updatedConversationSuccessfully:NO];
			}
		}
	}
}

- (void)at_APIRequestDidProgress:(ApptentiveAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)sender {
	@synchronized(self) {
		ApptentiveLogInfo(@"Conversation request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		if (creatingConversation) {
			[self.delegate conversationUpdater:self createdConversationSuccessfully:NO];
		} else {
			[self.delegate conversationUpdater:self updatedConversationSuccessfully:NO];
		}
	}
}

#pragma mark - Private methods

- (void)processResult:(NSDictionary *)jsonActivityFeed {
	if (creatingConversation) {
		ApptentiveConversation *conversation = (ApptentiveConversation *)[ApptentiveConversation newInstanceWithJSON:jsonActivityFeed];
		if (conversation) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSData *conversationData = [NSKeyedArchiver archivedDataWithRootObject:conversation];
			[defaults setObject:conversationData forKey:ATCurrentConversationPreferenceKey];
			[defaults setObject:[conversation apiUpdateJSON] forKey:ATConversationLastUpdateValuePreferenceKey];
			[defaults setObject:[NSDate date] forKey:ATConversationLastUpdatePreferenceKey];
			if (![defaults synchronize]) {
				ApptentiveLogError(@"Unable to synchronize defaults for conversation creation.");
				[self.delegate conversationUpdater:self createdConversationSuccessfully:NO];
			} else {
				ApptentiveLogInfo(@"Conversation created successfully.");
				[self.delegate conversationUpdater:self createdConversationSuccessfully:YES];
				[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveConversationCreatedNotification object:conversation userInfo:@{ @"token": conversation.token }];
			}
		} else {
			ApptentiveLogError(@"Unable to create conversation");
			[self.delegate conversationUpdater:self createdConversationSuccessfully:NO];
		}
		conversation = nil;
	} else {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		ApptentiveConversation *conversation = [ApptentiveConversationUpdater currentConversation];
		[defaults setObject:[conversation apiUpdateJSON] forKey:ATConversationLastUpdateValuePreferenceKey];
		[defaults setObject:[NSDate date] forKey:ATConversationLastUpdatePreferenceKey];
		[self.delegate conversationUpdater:self updatedConversationSuccessfully:YES];
	}
}
@end

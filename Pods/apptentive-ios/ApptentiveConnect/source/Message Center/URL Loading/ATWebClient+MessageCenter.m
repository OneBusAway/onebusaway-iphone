//
//  ATWebClient+MessageCenter.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveWebClient+MessageCenter.h"

#import "ApptentiveAPIRequest.h"
#import "ApptentiveBackend.h"
#import "ApptentiveMessage.h"
#import "ApptentiveFileAttachment.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveURLConnection.h"
#import "ApptentiveWebClient_Private.h"

#define kMessageCenterChannelName (@"Message Center")


@implementation ApptentiveWebClient (MessageCenter)
- (ApptentiveAPIRequest *)requestForCreatingConversation:(ApptentiveConversation *)conversation {
	NSError *error = nil;
	NSDictionary *postJSON = nil;
	if (conversation == nil) {
		postJSON = [NSDictionary dictionary];
	} else {
		postJSON = [conversation apiJSON];
	}
	NSString *postString = [ApptentiveJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ApptentiveLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}

	ApptentiveURLConnection *conn = [self connectionToPost:@"/conversation" JSON:postString];
	conn.timeoutInterval = 60.0;
	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}

- (ApptentiveAPIRequest *)requestForUpdatingConversation:(ApptentiveConversation *)conversation {
	NSError *error = nil;
	NSDictionary *putJSON = nil;
	if (conversation == nil) {
		return nil;
	}
	putJSON = [conversation apiUpdateJSON];
	NSString *putString = [ApptentiveJSONSerialization stringWithJSONObject:putJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!putString && error != nil) {
		ApptentiveLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}

	ApptentiveURLConnection *conn = [self connectionToPut:@"/conversation" JSON:putString];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}

- (ApptentiveAPIRequest *)requestForUpdatingDevice:(ApptentiveDeviceInfo *)deviceInfo {
	NSError *error = nil;
	NSDictionary *postJSON = [deviceInfo apiJSON];

	NSString *postString = [ApptentiveJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ApptentiveLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}

	ApptentiveConversation *conversation = [ApptentiveConversationUpdater currentConversation];
	if (!conversation) {
		ApptentiveLogError(@"No current conversation.");
		return nil;
	}

	ApptentiveURLConnection *conn = [self connectionToPut:@"/devices" JSON:postString];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}

- (ApptentiveAPIRequest *)requestForUpdatingPerson:(ApptentivePersonInfo *)personInfo {
	NSError *error = nil;
	NSDictionary *postJSON = [personInfo apiJSON];

	NSString *postString = [ApptentiveJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ApptentiveLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}

	ApptentiveConversation *conversation = [ApptentiveConversationUpdater currentConversation];
	if (!conversation) {
		ApptentiveLogError(@"No current conversation.");
		return nil;
	}

	ApptentiveURLConnection *conn = [self connectionToPut:@"/people" JSON:postString];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}

- (ApptentiveAPIRequest *)requestForPostingMessage:(ApptentiveMessage *)message {
	NSError *error = nil;
	NSDictionary *postJSON = [message apiJSON];

	NSString *postString = [ApptentiveJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ApptentiveLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}

	ApptentiveConversation *conversation = [ApptentiveConversationUpdater currentConversation];
	if (!conversation) {
		ApptentiveLogError(@"No current conversation");
		return nil;
	}

	ApptentiveURLConnection *conn = [self connectionToPost:@"/messages" JSON:postString withAttachments:message.attachments.array];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}

- (ApptentiveAPIRequest *)requestForRetrievingMessagesSinceMessage:(ApptentiveMessage *)message {
	NSDictionary *parameters = nil;
	if (message && message.apptentiveID) {
		parameters = @{ @"after_id": message.apptentiveID };
	}

	ApptentiveConversation *conversation = [ApptentiveConversationUpdater currentConversation];
	if (!conversation) {
		ApptentiveLogError(@"No current conversation.");
		return nil;
	}

	NSString *path = @"/conversation";
	if (parameters) {
		NSString *paramString = [self stringForParameters:parameters];
		path = [NSString stringWithFormat:@"%@?%@", path, paramString];
	}

	ApptentiveURLConnection *conn = [self connectionToGet:path];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}
@end

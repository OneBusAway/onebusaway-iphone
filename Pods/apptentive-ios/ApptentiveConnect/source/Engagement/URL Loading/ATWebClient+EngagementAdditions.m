//
//  ATWebClient+EngagementAdditions.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveWebClient+EngagementAdditions.h"
#import "ApptentiveWebClient_Private.h"
#import "ApptentiveURLConnection.h"
#import "ApptentiveAPIRequest.h"
#import "ApptentiveConversationUpdater.h"


@implementation ApptentiveWebClient (EngagementAdditions)

- (ApptentiveAPIRequest *)requestForGettingEngagementManifest {
	ApptentiveURLConnection *conn = [self connectionToGet:@"/interactions"];
	conn.timeoutInterval = 20.0;

	ApptentiveConversation *conversation = [ApptentiveConversationUpdater currentConversation];
	if (!conversation) {
		ApptentiveLogError(@"No current conversation.");
		return nil;
	}
	[self updateConnection:conn withOAuthToken:conversation.token];

	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ApptentiveAPIRequestReturnTypeData;
	return request;
}

@end

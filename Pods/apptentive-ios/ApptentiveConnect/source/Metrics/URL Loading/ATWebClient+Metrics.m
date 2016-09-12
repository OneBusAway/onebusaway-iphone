//
//  ATWebClient+Metrics.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive. All rights reserved.
//

#import "ApptentiveWebClient+Metrics.h"
#import "ApptentiveWebClient_Private.h"
#import "ApptentiveAPIRequest.h"
#import "ApptentiveBackend.h"
#import "Apptentive.h"
#import "ApptentiveEvent.h"
#import "ApptentiveMetric.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveURLConnection.h"


@implementation ApptentiveWebClient (Metrics)
- (ApptentiveAPIRequest *)requestForSendingMetric:(ApptentiveMetric *)metric {
	NSDictionary *postData = [metric apiDictionary];

	ApptentiveURLConnection *conn = [self connectionToPost:@"/records" parameters:postData];
	conn.timeoutInterval = 240.0;
	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:ATWebClientDefaultChannelName];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}

- (ApptentiveAPIRequest *)requestForSendingEvent:(ApptentiveEvent *)event {
	NSDictionary *postJSON = [event apiJSON];
	if (postJSON == nil) {
		return nil;
	}

	NSError *error = nil;
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

	ApptentiveURLConnection *conn = [self connectionToPost:@"/events" JSON:postString];
	conn.timeoutInterval = 240.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:ATWebClientDefaultChannelName];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}
@end

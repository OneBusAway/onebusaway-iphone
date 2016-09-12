//
//  ATWebClient+SurveyAdditions.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveWebClient+SurveyAdditions.h"
#import "ApptentiveWebClient_Private.h"
#import "ApptentiveAPIRequest.h"
#import "ApptentiveConversationUpdater.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveSurveyResponse.h"
#import "ApptentiveURLConnection.h"


@implementation ApptentiveWebClient (SurveyAdditions)

- (ApptentiveAPIRequest *)requestForPostingSurveyResponse:(ApptentiveSurveyResponse *)surveyResponse {
	ApptentiveConversation *conversation = [ApptentiveConversationUpdater currentConversation];
	if (!conversation) {
		ApptentiveLogError(@"No current conversation.");
		return nil;
	}

	NSError *error = nil;
	NSString *postString = [ApptentiveJSONSerialization stringWithJSONObject:[surveyResponse apiJSON] options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ApptentiveLogError(@"ATWebClient+SurveyAdditions: Error while encoding JSON: %@", error);
		return nil;
	}
	NSString *path = [NSString stringWithFormat:@"/surveys/%@/respond", surveyResponse.surveyID];

	ApptentiveURLConnection *conn = [self connectionToPost:path JSON:postString];
	conn.timeoutInterval = 240.0;
	[self updateConnection:conn withOAuthToken:conversation.token];

	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}
@end

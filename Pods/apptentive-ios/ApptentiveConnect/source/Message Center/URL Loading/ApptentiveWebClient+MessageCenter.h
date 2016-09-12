//
//  ApptentiveWebClient+MessageCenter.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveWebClient.h"

#import "ApptentiveConversation.h"
#import "ApptentiveDeviceInfo.h"
#import "ApptentiveMessage.h"
#import "ApptentivePersonInfo.h"


@interface ApptentiveWebClient (MessageCenter)
- (ApptentiveAPIRequest *)requestForCreatingConversation:(ApptentiveConversation *)conversation;
- (ApptentiveAPIRequest *)requestForUpdatingConversation:(ApptentiveConversation *)conversation;

- (ApptentiveAPIRequest *)requestForUpdatingDevice:(ApptentiveDeviceInfo *)deviceInfo;
- (ApptentiveAPIRequest *)requestForUpdatingPerson:(ApptentivePersonInfo *)personInfo;
- (ApptentiveAPIRequest *)requestForPostingMessage:(ApptentiveMessage *)message;
- (ApptentiveAPIRequest *)requestForRetrievingMessagesSinceMessage:(ApptentiveMessage *)message;
@end

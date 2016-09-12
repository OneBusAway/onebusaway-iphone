//
//  ApptentiveGetMessagesTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/12/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveTask.h"
#import "ApptentiveAPIRequest.h"
#import "ApptentiveMessage.h"

static NSString *const ATMessagesLastRetrievedMessageIDPreferenceKey;


@interface ApptentiveGetMessagesTask : ApptentiveTask <ApptentiveAPIRequestDelegate>
@end

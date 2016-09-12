//
//  ApptentiveMessageTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAPIRequest.h"
#import "ApptentiveTask.h"
#import "ApptentiveMessage.h"


@interface ApptentiveMessageTask : ApptentiveTask <ApptentiveAPIRequestDelegate>

@property (copy, nonatomic) NSString *pendingMessageID;

@end

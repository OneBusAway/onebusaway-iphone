//
//  ApptentiveRecordRequestTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/10/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveTask.h"
#import "ApptentiveAPIRequest.h"

typedef enum {
	ATRecordRequestTaskFailedResult,
	ATRecordRequestTaskFinishedResult,
} ATRecordRequestTaskResult;

@class ApptentiveEvent;


@interface ApptentiveRecordRequestTask : ApptentiveTask <ApptentiveAPIRequestDelegate>

@property (strong, nonatomic) ApptentiveEvent *event;

@end

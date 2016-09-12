//
//  ApptentiveSurveyResponseTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveTask.h"
#import "ApptentiveAPIRequest.h"
#import "ApptentiveSurveyResponse.h"


@interface ApptentiveSurveyResponseTask : ApptentiveTask <ApptentiveAPIRequestDelegate>
@property (copy, nonatomic) NSString *pendingSurveyResponseID;
@end

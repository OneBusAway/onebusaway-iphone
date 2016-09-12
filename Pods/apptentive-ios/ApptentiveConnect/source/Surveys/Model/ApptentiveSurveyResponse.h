//
//  ApptentiveSurveyResponse.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ApptentiveJSONModel.h"
#import "ApptentiveRecord.h"

typedef enum {
	ATPendingSurveyResponseStateSending,
	ATPendingSurveyResponseConfirmed,
	ATPendingSurveyResponseError
} ATPendingSurveyResponseState;


@interface ApptentiveSurveyResponse : ApptentiveRecord <ApptentiveJSONModel>
@property (copy, nonatomic) NSString *pendingSurveyResponseID;
@property (copy, nonatomic) NSData *answersData;
@property (copy, nonatomic) NSString *surveyID;
@property (strong, nonatomic) NSNumber *pendingState;

- (void)setAnswers:(NSDictionary *)answers;
+ (ApptentiveSurveyResponse *)findSurveyResponseWithPendingID:(NSString *)pendingID;
@end

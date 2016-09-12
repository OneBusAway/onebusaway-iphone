//
//  ApptentiveWebClient+SurveyAdditions.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveWebClient.h"

@class ApptentiveAPIRequest;
@class ATLegacySurveyResponse;
@class ApptentiveSurveyResponse;


@interface ApptentiveWebClient (SurveyAdditions)
- (ApptentiveAPIRequest *)requestForPostingSurveyResponse:(ApptentiveSurveyResponse *)surveyResponse;
@end

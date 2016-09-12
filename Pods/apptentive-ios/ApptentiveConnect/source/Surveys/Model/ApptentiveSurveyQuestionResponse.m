//
//  ApptentiveSurveyQuestionResponse.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/22/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyQuestionResponse.h"

#define kATSurveyQuestionResponseStorageVersion 1


@implementation ApptentiveSurveyQuestionResponse

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATSurveyQuestionResponse"];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"survey_question_response_version"];
		if (version == kATSurveyQuestionResponseStorageVersion) {
			self.identifier = [coder decodeObjectForKey:@"identifier"];
			self.response = [coder decodeObjectForKey:@"response"];
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATSurveyQuestionResponseStorageVersion forKey:@"survey_question_response_version"];
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeObject:self.response forKey:@"response"];
}

@end

//
//  ApptentiveSurveyAnswer.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/29/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyAnswer.h"


@implementation ApptentiveSurveyAnswer

- (instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		_identifier = JSON[@"id"];
		_value = JSON[@"value"];
		_type = [JSON[@"type"] isEqualToString:@"select_other"] ? ApptentiveSurveyAnswerTypeOther : ApptentiveSurveyAnswerTypeChoice;
		_placeholder = JSON[@"hint"];
	}

	return self;
}

- (instancetype)initWithValue:(NSString *)value {
	self = [super init];

	if (self) {
		_value = value;
		_type = ApptentiveSurveyAnswerTypeChoice;
	}

	return self;
}

@end

//
//  ApptentiveSurveyQuestion.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/29/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ATSurveyQuestionType) {
	ATSurveyQuestionTypeSingleSelect,
	ATSurveyQuestionTypeMultipleSelect,
	ATSurveyQuestionTypeSingleLine,
	ATSurveyQuestionTypeMultipleLine,
	ATSurveyQuestionTypeRange
};

@class ApptentiveSurveyAnswer;


@interface ApptentiveSurveyQuestion : NSObject

- (instancetype)initWithJSON:(NSDictionary *)JSON;

@property (readonly, nonatomic) ATSurveyQuestionType type;
@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *instructions;
@property (readonly, nonatomic) NSString *value;
@property (readonly, nonatomic) NSString *placeholder;
@property (readonly, nonatomic) BOOL required;
@property (readonly, nonatomic) NSInteger minimumSelectedCount;
@property (readonly, nonatomic) NSInteger maximumSelectedCount;

@property (readonly, nonatomic) NSInteger minimumValue;
@property (readonly, nonatomic) NSInteger maximumValue;
@property (readonly, nonatomic) NSString *minimumLabel;
@property (readonly, nonatomic) NSString *maximumLabel;

@property (readonly, nonatomic) NSArray<ApptentiveSurveyAnswer *> *answers;

@end

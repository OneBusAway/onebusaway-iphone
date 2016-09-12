//
//  ApptentiveSurveyAnswer.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/29/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ApptentiveSurveyAnswerType) {
	ApptentiveSurveyAnswerTypeChoice,
	ApptentiveSurveyAnswerTypeOther
};


@interface ApptentiveSurveyAnswer : NSObject

- (instancetype)initWithJSON:(NSDictionary *)JSON;
- (instancetype)initWithValue:(NSString *)value;

@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *value;
@property (readonly, nonatomic) NSString *placeholder;
@property (readonly, nonatomic) ApptentiveSurveyAnswerType type;

@end

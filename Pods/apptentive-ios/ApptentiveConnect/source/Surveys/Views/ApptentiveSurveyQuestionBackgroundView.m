//
//  ApptentiveSurveyQuestionBackgroundView.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyQuestionBackgroundView.h"
#import "ApptentiveSurveyLayoutAttributes.h"


@implementation ApptentiveSurveyQuestionBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	if (self) {
		self.layer.cornerRadius = 2.0;
		self.backgroundColor = [UIColor whiteColor];
		self.valid = YES;
	}

	return self;
}

- (void)setValid:(BOOL)valid {
	_valid = valid;

	self.layer.borderColor = (valid ? self.validColor : self.invalidColor).CGColor;
	self.layer.borderWidth = valid ? 1.0 / [UIScreen mainScreen].scale : 1.0;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
	[super applyLayoutAttributes:layoutAttributes];

	if ([layoutAttributes isKindOfClass:[ApptentiveSurveyLayoutAttributes class]]) {
		ApptentiveSurveyLayoutAttributes *surveyLayoutAttributes = (ApptentiveSurveyLayoutAttributes *)layoutAttributes;
		self.validColor = surveyLayoutAttributes.validColor;
		self.invalidColor = surveyLayoutAttributes.invalidColor;
		self.backgroundColor = surveyLayoutAttributes.backgroundColor;
		self.valid = surveyLayoutAttributes.valid;
	}
}

@end

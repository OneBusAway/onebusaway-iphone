//
//  ApptentiveSurveyLayoutAttributes.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyLayoutAttributes.h"


@implementation ApptentiveSurveyLayoutAttributes

- (id)copyWithZone:(NSZone *)zone {
	ApptentiveSurveyLayoutAttributes *result = [super copyWithZone:zone];

	result.valid = self.valid;
	result.validColor = [self.validColor copy];
	result.invalidColor = [self.invalidColor copy];
	result.backgroundColor = [self.backgroundColor copy];

	return result;
}

- (BOOL)isEqual:(id)object {
	if ([super isEqual:object]) {
		ApptentiveSurveyLayoutAttributes *other = (ApptentiveSurveyLayoutAttributes *)object;
		return self.valid == other.valid && [self.validColor isEqual:other.validColor] && [self.invalidColor isEqual:other.invalidColor] && [self.backgroundColor isEqual:other.backgroundColor];
	} else {
		return NO;
	}
}

@end

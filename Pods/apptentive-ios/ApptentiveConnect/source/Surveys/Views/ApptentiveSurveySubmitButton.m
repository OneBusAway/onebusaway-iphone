//
//  ApptentiveSurveySubmitButton.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 2/11/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveySubmitButton.h"


@implementation ApptentiveSurveySubmitButton

- (void)awakeFromNib {
	self.titleEdgeInsets = UIEdgeInsetsMake(4.0, 26.0, 4.0, 26.0);

	self.layer.borderWidth = 1.0;
	self.layer.cornerRadius = 6.0;

	[super awakeFromNib];
}

- (CGSize)intrinsicContentSize {
	CGSize s = [super intrinsicContentSize];

	return CGSizeMake(s.width + self.titleEdgeInsets.left + self.titleEdgeInsets.right, s.height + self.titleEdgeInsets.top + self.titleEdgeInsets.bottom);
}

- (void)layoutSubviews {
	[super layoutSubviews];

	// -awakeFromNib is too early for this
	self.layer.borderColor = self.tintColor.CGColor;
}

@end

//
//  ApptentiveSurveyChoiceCell.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyChoiceCell.h"


@implementation ApptentiveSurveyChoiceCell

- (void)awakeFromNib {
	self.isAccessibilityElement = YES;

	// We set the number of lines to zero here (rather than IB) to avoid an Xcode warning
	// for iOS 7. But we don't want to change the number of lines for range question types.
	// Using the tag, we can customize this on a per cell-prototype basis.
	self.textLabel.numberOfLines = self.textLabel.tag;

	[super awakeFromNib];
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];

	[self.button setHighlighted:selected];
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];

	[self.button setHighlighted:highlighted];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	self.textLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.textLabel.bounds);
}

@end

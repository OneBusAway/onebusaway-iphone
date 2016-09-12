//
//  ApptentiveSurveyOtherCell.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/4/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyOtherCell.h"


@implementation ApptentiveSurveyOtherCell

- (void)awakeFromNib {
	self.textField.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	self.textField.layer.cornerRadius = 5.0;
	self.valid = YES;

	[super awakeFromNib];
}

- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates {
	if (self.bounds.size.height > self.textField.frame.origin.y) {
		return [super resizableSnapshotViewFromRect:self.bounds afterScreenUpdates:afterUpdates withCapInsets:UIEdgeInsetsMake(self.bounds.size.height / 2, 0, 0, 0)];
	} else {
		return [super resizableSnapshotViewFromRect:self.bounds afterScreenUpdates:afterUpdates withCapInsets:UIEdgeInsetsMake(self.bounds.size.height - 1, 0, 0, 0)];
	}
}

- (void)setValid:(BOOL)valid {
	_valid = valid;

	self.textField.layer.borderColor = (valid ? self.validColor : self.invalidColor).CGColor;
	self.textField.layer.borderWidth = valid ? 1.0 / [UIScreen mainScreen].scale : 1.0;
}

@end

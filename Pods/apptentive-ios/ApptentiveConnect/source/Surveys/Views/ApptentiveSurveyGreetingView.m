//
//  ApptentiveSurveyGreetingView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 3/1/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyGreetingView.h"


@interface ApptentiveSurveyGreetingView ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *borderViewHeight;

@end


@implementation ApptentiveSurveyGreetingView

- (void)awakeFromNib {
	self.borderViewHeight.constant = 1.0 / [UIScreen mainScreen].scale;

	self.greetingLabel.numberOfLines = 0;

	[super awakeFromNib];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	self.greetingLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.greetingLabel.bounds);

	[super layoutSubviews];
}

@end

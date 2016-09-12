//
//  ApptentiveMessageCenterInputView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/14/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterInputView.h"


@interface ApptentiveMessageCenterInputView ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendBarLeadingToSuperview;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textViewTrailingToSuperview;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendBarBottomToTextView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleLabelToClearButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *clearButtonToAttachButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *attachButtonToSendButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonBaselines;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonCenters;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendButtonVerticalCenter;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *clearButtonLeadingToSuperview;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *outerTopSpace;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *outerBottomSpace;
@property (assign, nonatomic) CGFloat regularOuterVerticalSpace;

@property (strong, nonatomic) NSArray *landscapeConstraints;
@property (strong, nonatomic) NSArray *portraitConstraints;

@property (strong, nonatomic) NSArray *landscapeSendBarConstraints;
@property (strong, nonatomic) NSArray *portraitSendBarConstraints;

@end


@implementation ApptentiveMessageCenterInputView

- (void)awakeFromNib {
	self.containerView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	self.sendBar.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;

	self.regularOuterVerticalSpace = self.outerTopSpace.constant;

	NSDictionary *views = @{ @"sendBar": self.sendBar,
		@"messageView": self.messageView };
	self.portraitConstraints = @[self.sendBarLeadingToSuperview, self.sendBarBottomToTextView, self.textViewTrailingToSuperview];

	self.landscapeConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[messageView]-(0)-[sendBar]-(0)-|" options:NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom metrics:nil views:views];

	self.portraitSendBarConstraints = @[self.titleLabelToClearButton, self.attachButtonToSendButton, self.clearButtonToAttachButton, self.buttonCenters, self.buttonBaselines, self.clearButtonLeadingToSuperview, self.sendButtonVerticalCenter];

	self.landscapeSendBarConstraints = @[[NSLayoutConstraint constraintWithItem:self.sendBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.clearButton attribute:NSLayoutAttributeTop multiplier:1.0 constant:0], [NSLayoutConstraint constraintWithItem:self.sendBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.sendButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:4.0], [NSLayoutConstraint constraintWithItem:self.attachButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.sendBar attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];

	[super awakeFromNib];
}

- (void)setOrientation:(UIInterfaceOrientation)orientation {
	_orientation = orientation;
	[self updateConstraints];
}

- (void)setBorderColor:(UIColor *)borderColor {
	_borderColor = borderColor;

	self.containerView.layer.borderColor = self.borderColor.CGColor;
	self.sendBar.layer.borderColor = self.borderColor.CGColor;
}

- (void)updateConstraints {
	CGFloat outerVerticalSpace = self.regularOuterVerticalSpace;

	if (UIInterfaceOrientationIsLandscape(self.orientation)) {
		self.titleLabel.alpha = 0;

		[self.containerView removeConstraints:self.portraitConstraints];
		[self.containerView addConstraints:self.landscapeConstraints];

		[self.sendBar removeConstraints:self.portraitSendBarConstraints];
		[self.sendBar addConstraints:self.landscapeSendBarConstraints];

		if (CGRectGetHeight(self.bounds) < 44.0 * 3.0) {
			outerVerticalSpace = 0.0;
		}
	} else {
		self.titleLabel.alpha = 1;

		[self.containerView removeConstraints:self.landscapeConstraints];
		[self.containerView addConstraints:self.portraitConstraints];

		[self.sendBar removeConstraints:self.landscapeSendBarConstraints];
		[self.sendBar addConstraints:self.portraitSendBarConstraints];
	}

	self.outerTopSpace.constant = outerVerticalSpace;
	self.outerBottomSpace.constant = outerVerticalSpace;

	[super updateConstraints];
}

@end

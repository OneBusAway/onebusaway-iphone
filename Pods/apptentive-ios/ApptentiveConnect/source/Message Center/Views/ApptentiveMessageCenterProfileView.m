//
//  ApptentiveMessageCenterProfileView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterProfileView.h"


@interface ApptentiveMessageCenterProfileView ()

@property (weak, nonatomic) IBOutlet UIView *buttonBar;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emailLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nameVerticalSpaceToEmail;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *emailVerticalSpaceToButtonBar;

@property (strong, nonatomic) NSLayoutConstraint *nameHorizontalSpaceToEmail;

@property (strong, nonatomic) NSArray *portraitFullConstraints;
@property (strong, nonatomic) NSArray *landscapeFullConstraints;

@property (strong, nonatomic) NSArray *portraitCompactConstraints;
@property (strong, nonatomic) NSArray *landscapeCompactConstraints;

@property (strong, nonatomic) NSArray *baseConstraints;

@end


@implementation ApptentiveMessageCenterProfileView

- (void)awakeFromNib {
	CGFloat borderWidth = 1.0 / [UIScreen mainScreen].scale;

	self.containerView.layer.borderWidth = borderWidth;
	self.buttonBar.layer.borderWidth = borderWidth;

	self.portraitFullConstraints = @[self.nameTrailingConstraint, self.emailLeadingConstraint, self.nameVerticalSpaceToEmail];
	self.portraitCompactConstraints = @[self.nameTrailingConstraint, self.emailLeadingConstraint];

	self.nameHorizontalSpaceToEmail = [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-8.0];
	NSLayoutConstraint *nameEmailTopAlignment = [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
	NSLayoutConstraint *nameEmailBottomAlignment = [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];

	self.landscapeFullConstraints = @[self.nameHorizontalSpaceToEmail, nameEmailTopAlignment, nameEmailBottomAlignment];
	self.landscapeCompactConstraints = @[self.emailLeadingConstraint, nameEmailTopAlignment, nameEmailBottomAlignment];

	// Find constraints common to both modes/orientations
	NSMutableSet *baseConstraintSet = [NSMutableSet setWithArray:self.containerView.constraints];
	[baseConstraintSet minusSet:[NSSet setWithArray:self.portraitFullConstraints]];
	self.baseConstraints = [baseConstraintSet allObjects];

	[super awakeFromNib];
}

- (BOOL)becomeFirstResponder {
	if (self.mode == ATMessageCenterProfileModeFull) {
		return [self.nameField becomeFirstResponder];
	} else {
		return [self.emailField becomeFirstResponder];
	}
}

- (void)setOrientation:(UIInterfaceOrientation)orientation {
	_orientation = orientation;
	[self updateConstraints];
	[self sizeToFit];
}

- (void)setBorderColor:(UIColor *)borderColor {
	_borderColor = borderColor;

	self.containerView.layer.borderColor = self.borderColor.CGColor;
	self.buttonBar.layer.borderColor = self.borderColor.CGColor;
}

- (void)updateConstraints {
	[self.containerView removeConstraints:self.containerView.constraints];
	[self.containerView addConstraints:self.baseConstraints];

	if (UIInterfaceOrientationIsLandscape(self.orientation)) {
		switch (self.mode) {
			case ATMessageCenterProfileModeFull:
				[self.containerView addConstraints:self.landscapeFullConstraints];
				break;

			case ATMessageCenterProfileModeCompact:
				[self.containerView addConstraints:self.landscapeCompactConstraints];
				break;
		}
	} else {
		switch (self.mode) {
			case ATMessageCenterProfileModeFull:
				[self.containerView addConstraints:self.portraitFullConstraints];
				break;

			case ATMessageCenterProfileModeCompact:
				[self.containerView addConstraints:self.portraitCompactConstraints];
				break;
		}
	}

	[super updateConstraints];
}

- (void)setMode:(ATMessageCenterProfileMode)mode {
	if (_mode != mode) {
		_mode = mode;

		CGFloat nameFieldAlpha;

		if (mode == ATMessageCenterProfileModeCompact) {
			self.requiredLabel.hidden = NO;
			nameFieldAlpha = 0;
			self.emailVerticalSpaceToButtonBar.constant = 37.0;
		} else {
			self.nameField.hidden = NO;
			nameFieldAlpha = 1;
			self.emailVerticalSpaceToButtonBar.constant = 16.0;
		}

		[self updateConstraints];

		[UIView animateWithDuration:0.25 animations:^{
			self.nameField.alpha = nameFieldAlpha;
			self.requiredLabel.alpha = 1.0 - nameFieldAlpha;
			
			[self layoutIfNeeded];
		} completion:^(BOOL finished) {
			if (nameFieldAlpha == 0) {
				self.nameField.hidden = YES;
			} else {
				self.requiredLabel.hidden = YES;
			}
		}];
	}
}

@end

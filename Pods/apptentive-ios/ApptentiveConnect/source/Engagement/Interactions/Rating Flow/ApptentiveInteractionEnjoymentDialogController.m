//
//  ApptentiveInteractionEnjoymentDialogController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 7/15/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionEnjoymentDialogController.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveEngagementBackend.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveInteraction.h"

NSString *const ATInteractionEnjoymentDialogEventLabelLaunch = @"launch";
NSString *const ATInteractionEnjoymentDialogEventLabelCancel = @"cancel";
NSString *const ATInteractionEnjoymentDialogEventLabelYes = @"yes";
NSString *const ATInteractionEnjoymentDialogEventLabelNo = @"no";


@interface ApptentiveInteractionEnjoymentDialogController ()

@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIAlertView *alertView;

@end


@implementation ApptentiveInteractionEnjoymentDialogController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"EnjoymentDialog"];
}

- (void)presentInteractionFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;

	if ([UIAlertController class]) {
		self.alertController = [self alertControllerWithInteraction:self.interaction];

		if (self.alertController) {
			[viewController presentViewController:self.alertController animated:YES completion:^{
				[self.interaction engage:ATInteractionEnjoymentDialogEventLabelLaunch fromViewController:self.viewController];
			}];
		}
	} else {
		self.alertView = [self alertViewWithInteraction:self.interaction];

		if (self.alertView) {
			[self.alertView show];
		}
	}
}

- (NSString *)title {
	NSString *title = self.interaction.configuration[@"title"] ?: [NSString stringWithFormat:ApptentiveLocalizedString(@"Do you love %@?", @"Title for enjoyment alert view. Parameter is app name."), [[Apptentive sharedConnection].backend appName]];

	return title;
}

- (NSString *)body {
	NSString *body = self.interaction.configuration[@"body"] ?: nil;

	return body;
}

- (NSString *)yesText {
	NSString *yesText = self.interaction.configuration[@"yes_text"] ?: ApptentiveLocalizedString(@"Yes", @"yes");

	return yesText;
}

- (NSString *)noText {
	NSString *noText = self.interaction.configuration[@"no_text"] ?: ApptentiveLocalizedString(@"No", @"no");

	return noText;
}

#pragma mark UIAlertController

- (UIAlertController *)alertControllerWithInteraction:(ApptentiveInteraction *)interaction {
	if (!self.title && !self.body) {
		ApptentiveLogError(@"Skipping display of Enjoyment Dialog that does not have a title or body.");
		return nil;
	}

	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.title message:self.body preferredStyle:UIAlertControllerStyleAlert];

	[alertController addAction:[UIAlertAction actionWithTitle:self.noText style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		if (!self.viewController) {
			UIViewController *candidateVC = [ApptentiveUtilities rootViewControllerForCurrentWindow];
			if (candidateVC) {
				self.viewController = candidateVC;
			}
		}
		
        [self.interaction engage:ATInteractionEnjoymentDialogEventLabelNo fromViewController:self.viewController];
	}]];

	[alertController addAction:[UIAlertAction actionWithTitle:self.yesText style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.interaction engage:ATInteractionEnjoymentDialogEventLabelYes fromViewController:self.viewController];
	}]];

	return alertController;
}

#pragma mark UIAlertView

- (UIAlertView *)alertViewWithInteraction:(ApptentiveInteraction *)interaction {
	if (!self.title && !self.body) {
		ApptentiveLogError(@"Skipping display of Enjoyment Dialog that does not have a title or body.");
		return nil;
	}

	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.title message:self.body delegate:self cancelButtonTitle:nil otherButtonTitles:self.noText, self.yesText, nil];

	return alertView;
}

#pragma mark UIAlertViewDelegate

- (void)didPresentAlertView:(UIAlertView *)alertView {
	[self.interaction engage:ATInteractionEnjoymentDialogEventLabelLaunch fromViewController:self.viewController];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == self.alertView) {
		if (buttonIndex == 0) { // no
			if (!self.viewController) {
				UIViewController *candidateVC = [ApptentiveUtilities rootViewControllerForCurrentWindow];
				if (candidateVC) {
					self.viewController = candidateVC;
				}
			}

			[self.interaction engage:ATInteractionEnjoymentDialogEventLabelNo fromViewController:self.viewController];
		} else if (buttonIndex == 1) { // yes
			[self.interaction engage:ATInteractionEnjoymentDialogEventLabelYes fromViewController:self.viewController];
		}
	}
}

- (void)dealloc {
	_alertView.delegate = nil;
}

@end

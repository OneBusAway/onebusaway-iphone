//
//  ApptentiveInteractionAppStoreController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/26/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionAppStoreController.h"
#import "Apptentive_Private.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveEngagementBackend.h"

NSString *const ATInteractionAppStoreRatingEventLabelLaunch = @"launch";
NSString *const ATInteractionAppStoreRatingEventLabelOpenAppStoreURL = @"open_app_store_url";
NSString *const ATInteractionAppStoreRatingEventLabelOpenStoreKit = @"open_store_kit";
NSString *const ATInteractionAppStoreRatingEventLabelOpenMacAppStore = @"open_mac_app_store";
NSString *const ATInteractionAppStoreRatingEventLabelUnableToRate = @"unable_to_rate";


@interface ApptentiveInteractionAppStoreController ()

@property (strong, nonatomic) UIViewController *viewController;

@end


@implementation ApptentiveInteractionAppStoreController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"AppStoreRating"];
}

- (void)presentInteractionFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;

	[self openAppStoreToRateApp];
}

- (NSString *)appID {
	NSString *appID = self.interaction.configuration[@"store_id"];
	if (appID.length == 0) {
		appID = [Apptentive sharedConnection].appID;
	}

	return appID;
}

- (void)openAppStoreToRateApp {
	NSString *method = self.interaction.configuration[@"method"];

	if ([method isEqualToString:@"app_store"]) {
		[self openAppStoreViaURL];
	} else if ([method isEqualToString:@"store_kit"]) {
		[self openAppStoreViaStoreKit];
	} else if ([method isEqualToString:@"mac_app_store"]) {
		[self openMacAppStore];
	} else {
		[self legacyOpenAppStoreToRateApp];
	}
}

- (void)legacyOpenAppStoreToRateApp {
#if TARGET_IPHONE_SIMULATOR
	[self showUnableToOpenAppStoreDialog];
#else
	if ([self shouldOpenAppStoreViaStoreKit]) {
		[self openAppStoreViaStoreKit];
	} else {
		[self openAppStoreViaURL];
	}
#endif
}

- (void)showUnableToOpenAppStoreDialog {
	[self.interaction engage:ATInteractionAppStoreRatingEventLabelUnableToRate fromViewController:self.viewController];

	NSString *title;
	NSString *message;
	NSString *cancelButtonTitle;
#if TARGET_IPHONE_SIMULATOR
	title = @"Unable to open the App Store";
	message = @"The iOS Simulator is unable to open the App Store app. Please try again on a real iOS device.";
	cancelButtonTitle = @"OK";
#else
	title = ApptentiveLocalizedString(@"Oops!", @"Unable to load the App Store title");
	message = ApptentiveLocalizedString(@"Unable to load the App Store", @"Unable to load the App Store message");
	cancelButtonTitle = ApptentiveLocalizedString(@"OK", @"OK button title");
#endif

	UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
	[errorAlert show];
}

- (BOOL)shouldOpenAppStoreViaStoreKit {
	return ([SKStoreProductViewController class] != NULL && [self appID]);
}

- (NSURL *)URLForRatingApp {
	NSString *urlString = self.interaction.configuration[@"url"];

	NSURL *ratingURL = (urlString) ? [NSURL URLWithString:urlString] : [self legacyURLForRatingApp];

	return ratingURL;
}

- (NSURL *)legacyURLForRatingApp {
	NSString *URLString = nil;

	if ([[[UIDevice currentDevice] systemVersion] compare:@"7.1" options:NSNumericSearch] != NSOrderedAscending) {
		URLString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", [self appID]];
	} else {
		URLString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/%@/app/id%@", [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode], [self appID]];
	}

	return [NSURL URLWithString:URLString];
}

- (void)openAppStoreViaURL {
	if ([self appID]) {
		NSURL *url = [self URLForRatingApp];

		BOOL attemptToOpenURL = [[UIApplication sharedApplication] canOpenURL:url];

		// In iOS 9, `canOpenURL:` returns NO unless that URL scheme has been added to LSApplicationQueriesSchemes.
		if (!attemptToOpenURL) {
			attemptToOpenURL = YES;
		}

		if (attemptToOpenURL) {
			[self.interaction engage:ATInteractionAppStoreRatingEventLabelOpenAppStoreURL fromViewController:self.viewController];

			BOOL openedURL = [[UIApplication sharedApplication] openURL:url];
			if (!openedURL) {
				ApptentiveLogError(@"Could not open App Store URL: %@", url);
			}
		} else {
			ApptentiveLogError(@"No application can open the URL: %@", url);
			[self showUnableToOpenAppStoreDialog];
		}
	} else {
		ApptentiveLogError(@"Could not open App Store because App ID is not set. Set the `appID` property locally, or configure it remotely via the Apptentive dashboard.");

		[self showUnableToOpenAppStoreDialog];
	}
}

- (void)openAppStoreViaStoreKit {
	if ([SKStoreProductViewController class] != NULL && [self appID]) {
		SKStoreProductViewController *vc = [[SKStoreProductViewController alloc] init];
		vc.delegate = self;
		[vc loadProductWithParameters:@{ SKStoreProductParameterITunesItemIdentifier: self.appID } completionBlock:^(BOOL result, NSError *error) {
			if (error) {
				ApptentiveLogError(@"Error loading product view: %@", error);
				[self showUnableToOpenAppStoreDialog];
			} else {
				[self.interaction engage:ATInteractionAppStoreRatingEventLabelOpenStoreKit fromViewController:self.viewController];
				
				UIViewController *presentingVC = self.viewController;

				if (!presentingVC) {
					ApptentiveLogError(@"Attempting to open the App Store via StoreKit from a nil View Controller!");
				} else {
					[presentingVC presentViewController:vc animated:YES completion:^{}];
				}
			}
		}];
	} else {
		[self showUnableToOpenAppStoreDialog];
	}
}

#pragma mark SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)productViewController {
	[productViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//Unable to open app store
}

- (void)openMacAppStore {
	[self.interaction engage:ATInteractionAppStoreRatingEventLabelOpenMacAppStore fromViewController:self.viewController];
}


@end

//
//  OBAFarePayments.m
//  OneBusAway
//
//  Created by Aaron Brethorst on 8/5/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import "OBAFarePayments.h"
#import "OBAAlerts.h"
@import StoreKit;

@interface OBAFarePayments () <SKStoreProductViewControllerDelegate>
@property(nonatomic,strong) OBAApplication *application;
@property(nonatomic,strong,readonly) OBARegionV2 *currentRegion;
@end

@implementation OBAFarePayments

- (instancetype)initWithApplication:(OBAApplication*)application delegate:(id<OBAFarePaymentsDelegate>)delegate {
    self = [super init];

    if (self) {
        _application = application;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Private Helpers

- (OBARegionV2*)currentRegion {
    return self.application.modelDao.currentRegion;
}

#pragma mark - Fare Payment

- (void)beginFarePaymentWorkflow {
    OBARegionV2 *region = self.currentRegion;

    if (region.paymentAppDoesNotCoverFullRegion && [self showPaymentWarningForRegion:region]) {
        [self displayPaymentAppWarningForRegion:region];
    }
    else {
        [self launchAppOrShowAppStoreForRegion:region];
    }
}

- (void)launchAppOrShowAppStoreForRegion:(OBARegionV2*)region {
    if ([UIApplication.sharedApplication canOpenURL:region.paymentAppDeepLinkURL]) {
        [UIApplication.sharedApplication openURL:region.paymentAppDeepLinkURL options:@{} completionHandler:nil];
    }
    else {
        [self displayAppStorePageForAppWithIdentifier:region.paymentAppStoreIdentifier];
    }
}

- (void)displayAppStorePageForAppWithIdentifier:(NSString*)identifier {
    SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
    storeViewController.delegate = self;

    id<OBAFarePaymentsDelegate> delegate = self.delegate;

    NSDictionary *params = @{SKStoreProductParameterITunesItemIdentifier: identifier};
    [storeViewController loadProductWithParameters:params completionBlock:nil];
    [delegate farePayments:self presentViewController:storeViewController animated:YES completion:nil];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)displayPaymentAppWarningForRegion:(OBARegionV2*)region {
    NSString *title = region.paymentWarningTitle;
    NSString *body = region.paymentWarningBody;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:body preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:OBAAlerts.buildCancelButton];

    UIAlertAction *dontShowAgain = [UIAlertAction actionWithTitle:NSLocalizedString(@"info_controller.payment.continue_dont_show_again", @"An alert button that says 'Continue and Do Not Show Again'") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.application.userDefaults setBool:YES forKey:[self suppressPaymentWarningUserDefaultsKeyForRegion:region]];
        [self launchAppOrShowAppStoreForRegion:region];
    }];
    [alert addAction:dontShowAgain];

    UIAlertAction *continueButton = [UIAlertAction actionWithTitle:OBAStrings.continueString style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self launchAppOrShowAppStoreForRegion:region];
    }];
    [alert addAction:continueButton];

    [self.delegate farePayments:self presentViewController:alert animated:YES completion:nil];
}

- (NSString*)suppressPaymentWarningUserDefaultsKeyForRegion:(OBARegionV2*)region {
    return [NSString stringWithFormat:@"SuppressPaymentWarning_Region_%@", @(region.identifier)];
}

- (BOOL)showPaymentWarningForRegion:(OBARegionV2*)region {
    NSString *key = [self suppressPaymentWarningUserDefaultsKeyForRegion:region];
    return ![self.application.userDefaults boolForKey:key];
}

@end

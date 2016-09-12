//
//  ApptentiveInteractionAppStoreController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/26/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionController.h"
#import <StoreKit/StoreKit.h>

@class ApptentiveInteraction;


@interface ApptentiveInteractionAppStoreController : ApptentiveInteractionController <SKStoreProductViewControllerDelegate, UIAlertViewDelegate>
@end

//
//  OBAFarePayments.h
//  OneBusAway
//
//  Created by Aaron Brethorst on 8/5/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import Foundation;
@import UIKit;
@import OBAKit;

NS_ASSUME_NONNULL_BEGIN

@class OBAFarePayments;
@protocol OBAFarePaymentsDelegate<NSObject>
- (void)farePayments:(OBAFarePayments*)farePayments presentViewController:(UIViewController*)viewController animated:(BOOL)animated completion:(void(^ _Nullable)(void))completion;
- (void)farePayments:(OBAFarePayments*)farePayments presentError:(NSError*)error;
@end

@interface OBAFarePayments : NSObject
@property(nonatomic,weak) id<OBAFarePaymentsDelegate> delegate;
- (instancetype)initWithApplication:(OBAApplication*)application delegate:(id<OBAFarePaymentsDelegate>)delegate;

- (void)beginFarePaymentWorkflow;
@end

NS_ASSUME_NONNULL_END

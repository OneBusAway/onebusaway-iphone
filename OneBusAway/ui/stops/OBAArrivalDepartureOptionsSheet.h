//
//  OBAArrivalDepartureOptionsSheet.h
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/3/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import UIKit;
@import OBAKit;

NS_ASSUME_NONNULL_BEGIN

@class OBAArrivalDepartureOptionsSheet;
@protocol OBAArrivalDepartureOptionsSheetDelegate<NSObject>

/**
 This method is called to request that the receiver presents the specified view controller, optionally from the `presentingView`.
 The best way to handle this is by calling `oba_presentViewController:fromView:`.

 @param optionsSheet The options sheet object.
 @param viewController The view controller to present.
 @param presentingView The nullable presenting view.
 */
- (void)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet presentViewController:(UIViewController*)viewController fromView:(nullable UIView*)presentingView;

/**
 This method is called to give the receiver a chance to specify which view should host a soon-to-be-presented view.

 @param optionsSheet The options sheet object.
 @return The view that should host a to-be-presented view. Usually this should be the `view` property of a view controller.
 */
- (UIView*)optionsSheetPresentationView:(OBAArrivalDepartureOptionsSheet*)optionsSheet;

/**
 This delegate method gives the receiver the opportunity to specify the source view that corresponds to the passed-in arrival and departure object. This is used to properly position popovers on screen on iPads.

 @param optionsSheet The options sheet object.
 @param arrivalAndDeparture The arrival and departure object that can be used to find the appropriate source view in the receiver.
 @return The source view corresponding to the arrival and departure object.
 */
- (UIView*)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet viewForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

@optional


/**
 This method is called when a new alarm is created.

 @param optionsSheet The options sheet object.
 @param alarm The newly created alarm object.
 @param arrivalDeparture The arrival and departure object that corresponds to the alarm.
 */
- (void)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet addedAlarm:(OBAAlarm*)alarm forArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalDeparture;

/**
 This method is called when the user successfully deletes an alarm.

 @param optionsSheet The options sheet object.
 @param arrivalAndDeparture The arrival and departure object that corresponds to the deleted alarm.
 */
- (void)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet deletedAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;
@end

@interface OBAArrivalDepartureOptionsSheet : NSObject
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) PromisedModelService *modelService;

- (instancetype)initWithDelegate:(id<OBAArrivalDepartureOptionsSheetDelegate>)delegate;

- (void)presentAlertToRemoveBookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep;

- (void)presentAlertToRemoveAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep;

- (void)createAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep;

- (void)showActionMenuForDepartureRow:(OBADepartureRow*)departureRow fromPresentingView:(UIView*)presentingView;
@end

NS_ASSUME_NONNULL_END

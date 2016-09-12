//
//  ApptentiveMessageCenterStatusView.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ATMessageCenterStatusMode) {
	ATMessageCenterStatusModeNotSet = 0,
	ATMessageCenterStatusModeEmpty,
	ATMessageCenterStatusModeStatus,
	ATMessageCenterStatusModeNetworkError,
	ATMessageCenterStatusModeHTTPError
};


@interface ApptentiveMessageCenterStatusView : UIView

@property (assign, nonatomic) ATMessageCenterStatusMode mode;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

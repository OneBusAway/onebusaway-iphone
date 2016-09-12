//
//  ApptentiveMessageCenterGreetingView.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ApptentiveNetworkImageIconView;


@interface ApptentiveMessageCenterGreetingView : UIView

@property (retain, nonatomic) IBOutlet ApptentiveNetworkImageIconView *imageView;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *aboutButton;
@property (weak, nonatomic) IBOutlet UIView *borderView;

@property (assign, nonatomic) BOOL isOnScreen;
@property (assign, nonatomic) UIInterfaceOrientation orientation;

@end

//
//  ApptentiveMessageCenterInputView.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/14/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ApptentiveAttachButton;


@interface ApptentiveMessageCenterInputView : UIView

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet ApptentiveAttachButton *attachButton;
@property (weak, nonatomic) IBOutlet UITextView *messageView;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *sendBar;

@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;

@property (assign, nonatomic) UIInterfaceOrientation orientation;
@property (strong, nonatomic) UIColor *borderColor;

@end

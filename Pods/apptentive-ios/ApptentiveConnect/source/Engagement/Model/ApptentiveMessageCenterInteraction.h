//
//  ApptentiveMessageCenterInteraction.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 5/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteraction.h"


@interface ApptentiveMessageCenterInteraction : ApptentiveInteraction

+ (id)interactionForInvokingMessageEvents;

+ (id)messageCenterInteractionFromInteraction:(ApptentiveInteraction *)interaction;

@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *branding;

@property (readonly, nonatomic) NSString *composerTitle;
@property (readonly, nonatomic) NSString *composerPlaceholderText;
@property (readonly, nonatomic) NSString *composerSendButtonTitle;
@property (readonly, nonatomic) NSString *composerCloseConfirmBody;
@property (readonly, nonatomic) NSString *composerCloseDiscardButtonTitle;
@property (readonly, nonatomic) NSString *composerCloseCancelButtonTitle;

@property (readonly, nonatomic) NSString *greetingTitle;
@property (readonly, nonatomic) NSString *greetingBody;
@property (readonly, nonatomic) NSURL *greetingImageURL;

@property (readonly, nonatomic) NSString *statusBody;

@property (readonly, nonatomic) NSString *contextMessageBody;

@property (readonly, nonatomic) NSString *HTTPErrorBody;
@property (readonly, nonatomic) NSString *networkErrorBody;

@property (readonly, nonatomic) BOOL profileRequested;
@property (readonly, nonatomic) BOOL profileRequired;

@property (readonly, nonatomic) NSString *profileInitialTitle;
@property (readonly, nonatomic) NSString *profileInitialNamePlaceholder;
@property (readonly, nonatomic) NSString *profileInitialEmailPlaceholder;
@property (readonly, nonatomic) NSString *profileInitialSkipButtonTitle;
@property (readonly, nonatomic) NSString *profileInitialSaveButtonTitle;
@property (readonly, nonatomic) NSString *profileInitialEmailExplanation;

@property (readonly, nonatomic) NSString *profileEditTitle;
@property (readonly, nonatomic) NSString *profileEditNamePlaceholder;
@property (readonly, nonatomic) NSString *profileEditEmailPlaceholder;
@property (readonly, nonatomic) NSString *profileEditSkipButtonTitle;
@property (readonly, nonatomic) NSString *profileEditSaveButtonTitle;

@end

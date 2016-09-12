//
//  ApptentiveMessageCenterInteraction.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 5/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterInteraction.h"
#import "ApptentiveEngagementBackend.h"
#import "Apptentive_Private.h"
#import "ApptentivePersonInfo.h"
#import "ApptentiveMessageCenterViewController.h"


@implementation ApptentiveMessageCenterInteraction

+ (id)interactionForInvokingMessageEvents {
	ApptentiveMessageCenterInteraction *messageCenterInteraction = [[ApptentiveMessageCenterInteraction alloc] init];
	messageCenterInteraction.type = @"MessageCenter";
	messageCenterInteraction.vendor = ATEngagementCodePointApptentiveVendorKey;

	return messageCenterInteraction;
}

+ (id)messageCenterInteractionFromInteraction:(ApptentiveInteraction *)interaction {
	ApptentiveMessageCenterInteraction *messageCenterInteraction = [[ApptentiveMessageCenterInteraction alloc] init];
	messageCenterInteraction.identifier = interaction.identifier;
	messageCenterInteraction.priority = interaction.priority;
	messageCenterInteraction.type = interaction.type;
	messageCenterInteraction.configuration = interaction.configuration;
	messageCenterInteraction.version = interaction.version;
	messageCenterInteraction.vendor = interaction.vendor;

	return messageCenterInteraction;
}

- (id)copyWithZone:(NSZone *)zone {
	ApptentiveMessageCenterInteraction *copy = (ApptentiveMessageCenterInteraction *)[super copyWithZone:zone];

	return copy;
}

- (NSString *)title {
	return self.configuration[@"title"];
}

- (NSString *)branding {
	return self.configuration[@"branding"];
}

#pragma mark - Composer

- (NSString *)composerTitle {
	return self.configuration[@"composer"][@"title"];
}

- (NSString *)composerPlaceholderText {
	return self.configuration[@"composer"][@"hint_text"];
}

- (NSString *)composerSendButtonTitle {
	return self.configuration[@"composer"][@"send_button"];
}

- (NSString *)composerCloseConfirmBody {
	return self.configuration[@"composer"][@"close_confirm_body"];
}

- (NSString *)composerCloseDiscardButtonTitle {
	return self.configuration[@"composer"][@"close_discard_button"];
}

- (NSString *)composerCloseCancelButtonTitle {
	return self.configuration[@"composer"][@"close_cancel_button"];
}

#pragma mark - Greeting

- (NSString *)greetingTitle {
	return self.configuration[@"greeting"][@"title"];
}

- (NSString *)greetingBody {
	return self.configuration[@"greeting"][@"body"];
}

- (NSURL *)greetingImageURL {
	NSString *URLString = self.configuration[@"greeting"][@"image_url"];

	return (URLString.length > 0) ? [NSURL URLWithString:URLString] : nil;
}

#pragma mark - Status

- (NSString *)statusBody {
	return self.configuration[@"status"][@"body"];
}

#pragma mark - Context / Automated Message

- (NSString *)contextMessageBody {
	return self.configuration[@"automated_message"][@"body"];
}

#pragma mark - Error Messages

- (NSString *)HTTPErrorBody {
	return self.configuration[@"error_messages"][@"http_error_body"];
}

- (NSString *)networkErrorBody {
	return self.configuration[@"error_messages"][@"network_error_body"];
}

#pragma mark - Profile

- (BOOL)profileRequested {
	return [self.configuration[@"profile"][@"request"] boolValue];
}

- (BOOL)profileRequired {
	return [self.configuration[@"profile"][@"require"] boolValue];
}

#pragma mark - Profile (Initial)

- (NSString *)profileInitialTitle {
	return self.configuration[@"profile"][@"initial"][@"title"];
}

- (NSString *)profileInitialNamePlaceholder {
	return self.configuration[@"profile"][@"initial"][@"name_hint"];
}

- (NSString *)profileInitialEmailPlaceholder {
	return self.configuration[@"profile"][@"initial"][@"email_hint"];
}

- (NSString *)profileInitialSkipButtonTitle {
	return self.configuration[@"profile"][@"initial"][@"skip_button"];
}

- (NSString *)profileInitialSaveButtonTitle {
	return self.configuration[@"profile"][@"initial"][@"save_button"];
}

- (NSString *)profileInitialEmailExplanation {
	return self.configuration[@"profile"][@"initial"][@"email_explanation"];
}

#pragma mark - Profile (Edit)

- (NSString *)profileEditTitle {
	return self.configuration[@"profile"][@"edit"][@"title"];
}

- (NSString *)profileEditNamePlaceholder {
	return self.configuration[@"profile"][@"edit"][@"name_hint"];
}

- (NSString *)profileEditEmailPlaceholder {
	return self.configuration[@"profile"][@"edit"][@"email_hint"];
}

- (NSString *)profileEditSkipButtonTitle {
	return self.configuration[@"profile"][@"edit"][@"skip_button"];
}

- (NSString *)profileEditSaveButtonTitle {
	return self.configuration[@"profile"][@"edit"][@"save_button"];
}

@end

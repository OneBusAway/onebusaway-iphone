//
//  ApptentiveConversationUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveAPIRequest.h"
#import "ApptentiveConversation.h"

extern NSString *const ATCurrentConversationPreferenceKey;

@protocol ApptentiveConversationUpdaterDelegate;


@interface ApptentiveConversationUpdater : NSObject <ApptentiveAPIRequestDelegate>
@property (weak, nonatomic) NSObject<ApptentiveConversationUpdaterDelegate> *delegate;
+ (BOOL)conversationExists;
+ (ApptentiveConversation *)currentConversation;
+ (BOOL)shouldUpdate;

- (id)initWithDelegate:(NSObject<ApptentiveConversationUpdaterDelegate> *)delegate;
- (void)createOrUpdateConversation;
- (void)cancel;
- (float)percentageComplete;
@end

@protocol ApptentiveConversationUpdaterDelegate <NSObject>
- (void)conversationUpdater:(ApptentiveConversationUpdater *)updater createdConversationSuccessfully:(BOOL)success;
- (void)conversationUpdater:(ApptentiveConversationUpdater *)updater updatedConversationSuccessfully:(BOOL)success;
@end

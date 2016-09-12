//
//  ApptentiveBackend.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "ApptentiveConversationUpdater.h"
#import "ApptentiveDeviceUpdater.h"
#import "ApptentivePersonUpdater.h"
#import "ApptentiveFileAttachment.h"
#import "ApptentiveMessage.h"

@class ApptentiveMessageCenterViewController;

extern NSString *const ATBackendBecameReadyNotification;

#define USE_STAGING 0

@class ApptentiveAppConfigurationUpdater;
@class ApptentiveDataManager;
@class ATFeedback;
@class ApptentiveAPIRequest;
@class ApptentiveMessageTask;

@protocol ATBackendMessageDelegate;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ApptentiveBackend : NSObject <ApptentiveConversationUpdaterDelegate, ATDeviceUpdaterDelegate, ATPersonUpdaterDelegate, NSFetchedResultsControllerDelegate, UIAlertViewDelegate>
/*! The feedback currently being worked on by the user. */
@property (strong, nonatomic) ATFeedback *currentFeedback;
@property (copy, nonatomic) NSDictionary *currentCustomData;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSString *supportDirectoryPath;
@property (strong, nonatomic) UIViewController *presentedMessageCenterViewController;

@property (readonly, assign, nonatomic) BOOL hideBranding;
@property (readonly, assign, nonatomic) BOOL notificationPopupsEnabled;

- (void)startup;

/*! Message send progress. */
@property (weak, nonatomic) id<ATBackendMessageDelegate> messageDelegate;
- (void)messageTaskDidBegin:(ApptentiveMessageTask *)messageTask;
- (void)messageTask:(ApptentiveMessageTask *)messageTask didProgress:(float)progress;
- (void)messageTaskDidFinish:(ApptentiveMessageTask *)messageTask;
- (void)messageTaskDidFail:(ApptentiveMessageTask *)messageTask;

+ (UIImage *)imageNamed:(NSString *)name;
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController;
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;
- (void)messageCenterWillDismiss:(ApptentiveMessageCenterViewController *)messageCenter;

- (void)attachCustomDataToMessage:(ApptentiveMessage *)message;
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;

/*! ATAutomatedMessage messages. */
- (ApptentiveMessage *)automatedMessageWithTitle:(NSString *)title body:(NSString *)body;
- (BOOL)sendAutomatedMessage:(ApptentiveMessage *)message;

/*! Send ATTextMessage messages. */
- (ApptentiveMessage *)createTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessageWithBody:(NSString *)body;
- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessage:(ApptentiveMessage *)message;
/*! Send ATFileMessage messages. */
- (BOOL)sendImageMessageWithImage:(UIImage *)image;
- (BOOL)sendImageMessageWithImage:(UIImage *)image hiddenOnClient:(BOOL)hidden;

- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType;
- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType hiddenOnClient:(BOOL)hidden;

- (BOOL)sendCompoundMessageWithText:(NSString *)text attachments:(NSArray *)attachments hiddenOnClient:(BOOL)hidden;

/*! Path to directory for storing attachments. */
- (NSString *)attachmentDirectoryPath;
- (NSString *)deviceUUID;

- (NSURL *)apptentiveHomepageURL;
- (NSURL *)apptentivePrivacyPolicyURL;

- (NSString *)distributionName;
- (NSString *)distributionVersion;

- (NSUInteger)unreadMessageCount;

- (void)messageCenterEnteredForeground;
- (void)messageCenterLeftForeground;

- (NSString *)appName;

- (BOOL)isReady;

- (void)checkForMessages;

- (void)fetchMessagesInBackground:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)completeMessageFetchWithResult:(UIBackgroundFetchResult)fetchResult;

/*! True if the backend is currently updating the person. */
- (BOOL)isUpdatingPerson;

- (void)updatePersonIfNeeded;

- (NSURLCache *)imageCache;

@end

@protocol ATBackendMessageDelegate <NSObject>

- (void)backend:(ApptentiveBackend *)backend messageProgressDidChange:(float)progress;

@end

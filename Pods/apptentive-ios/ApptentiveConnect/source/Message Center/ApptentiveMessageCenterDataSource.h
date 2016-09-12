//
//  ApptentiveMessageCenterDataSource.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ApptentiveMessage.h"

typedef NS_ENUM(NSInteger, ATMessageCenterMessageType) {
	ATMessageCenterMessageTypeMessage,
	ATMessageCenterMessageTypeReply,
	ATMessageCenterMessageTypeContextMessage,
	ATMessageCenterMessageTypeCompoundMessage,
	ATMessageCenterMessageTypeCompoundReply
};

typedef NS_ENUM(NSInteger, ATMessageCenterMessageStatus) {
	ATMessageCenterMessageStatusHidden,
	ATMessageCenterMessageStatusSending,
	ATMessageCenterMessageStatusSent,
	ATMessageCenterMessageStatusFailed,
};

@protocol ApptentiveMessageCenterDataSourceDelegate;


@interface ApptentiveMessageCenterDataSource : NSObject <NSURLSessionDownloadDelegate>
@property (readonly, strong, nonatomic) NSFetchedResultsController *fetchedMessagesController;
@property (weak, nonatomic) NSObject<ApptentiveMessageCenterDataSourceDelegate> *delegate;
@property (readonly, nonatomic) NSDateFormatter *dateFormatter;

- (id)initWithDelegate:(NSObject<ApptentiveMessageCenterDataSourceDelegate> *)delegate;
- (void)start;
- (void)stop;

- (BOOL)hasNonContextMessages;

- (NSInteger)numberOfMessageGroups;
- (NSInteger)numberOfMessagesInGroup:(NSInteger)groupIndex;
- (ATMessageCenterMessageType)cellTypeAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)textOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (NSDate *)dateOfMessageGroupAtIndex:(NSInteger)index;
- (ATMessageCenterMessageStatus)statusOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)shouldShowDateForMessageGroupAtIndex:(NSInteger)index;
- (NSString *)senderOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (NSURL *)imageURLOfSenderAtIndexPath:(NSIndexPath *)indexPath;
- (void)markAsReadMessageAtIndexPath:(NSIndexPath *)indexPath;

- (void)removeUnsentContextMessages;

- (NSInteger)numberOfAttachmentsForMessageAtIndex:(NSInteger)index;
- (BOOL)shouldUsePlaceholderForAttachmentAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canPreviewAttachmentAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)extensionForAttachmentAtIndexPath:(NSIndexPath *)indexPath;			   // Returns nil if thumbnail is present, file extension if not
- (UIImage *)imageForAttachmentAtIndexPath:(NSIndexPath *)indexPath size:(CGSize)size; // Returns thumbnail if present, generic file icon if not
- (void)downloadAttachmentAtIndexPath:(NSIndexPath *)indexPath;
- (id<QLPreviewControllerDataSource>)previewDataSourceAtIndex:(NSInteger)index;

@property (readonly, nonatomic) BOOL lastMessageIsReply;
@property (readonly, nonatomic) ATPendingMessageState lastUserMessageState;

@end

@protocol ApptentiveMessageCenterDataSourceDelegate <NSObject, NSFetchedResultsControllerDelegate>

- (void)messageCenterDataSource:(ApptentiveMessageCenterDataSource *)dataSource attachmentDownloadAtIndexPath:(NSIndexPath *)indexPath didProgress:(float)progress;
- (void)messageCenterDataSource:(ApptentiveMessageCenterDataSource *)dataSource didLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath;
- (void)messageCenterDataSource:(ApptentiveMessageCenterDataSource *)dataSource didFailToLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath error:(NSError *)error;

@end

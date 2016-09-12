//
//  ApptentiveMessageSender.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ApptentiveMessage;


@interface ApptentiveMessageSender : NSManagedObject

@property (copy, nonatomic) NSString *apptentiveID;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *emailAddress;
@property (copy, nonatomic) NSString *profilePhotoURL;
@property (strong, nonatomic) NSSet *sentMessages;
@property (strong, nonatomic) NSSet *receivedMessages;

+ (ApptentiveMessageSender *)findSenderWithID:(NSString *)apptentiveID;
+ (ApptentiveMessageSender *)newOrExistingMessageSenderFromJSON:(NSDictionary *)json;
- (NSDictionary *)apiJSON;
@end


@interface ApptentiveMessageSender (CoreDataGeneratedAccessors)

- (void)addSentMessagesObject:(ApptentiveMessage *)value;
- (void)removeSentMessagesObject:(ApptentiveMessage *)value;
- (void)addSentMessages:(NSSet *)values;
- (void)removeSentMessages:(NSSet *)values;

- (void)addReceivedMessagesObject:(ApptentiveMessage *)value;
- (void)removeReceivedMessagesObject:(ApptentiveMessage *)value;
- (void)addReceivedMessages:(NSSet *)values;
- (void)removeReceivedMessages:(NSSet *)values;

@end

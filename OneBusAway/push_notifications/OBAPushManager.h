//
//  OBAPushManager.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 1/10/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;
@import OneSignal;
@import PromiseKit;

NS_ASSUME_NONNULL_BEGIN

@class OBAPushManager;
@protocol OBAPushManagerDelegate <NSObject>
- (void)pushManager:(OBAPushManager*)pushManager notificationReceivedWithTitle:(NSString*)title message:(NSString*)message data:(nullable NSDictionary*)data;
@end

extern NSString * const OBAPushNotificationUserIdDefaultsKey;
extern NSString * const OBAPushNotificationPushTokenDefaultsKey;

@interface OBAPushManager : NSObject
@property(nonatomic,copy,readonly) NSString *pushNotificationUserID;
@property(nonatomic,copy,readonly) NSString *pushNotificationToken;
@property(nonatomic,weak) id<OBAPushManagerDelegate> delegate;

+ (instancetype)pushManager;

- (void)startWithLaunchOptions:(NSDictionary*)launchOptions delegate:(id<OBAPushManagerDelegate>)delegate APIKey:(NSString*)APIKey;

- (AnyPromise*)requestUserPushNotificationID;

@end

NS_ASSUME_NONNULL_END

//
//  OBAPushManager.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 1/10/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBAPushManager.h"
@import OBAKit;
@import UIKit;

NSString * const OBAPushNotificationUserIdDefaultsKey = @"OBAPushNotificationUserIdDefaultsKey";
NSString * const OBAPushNotificationPushTokenDefaultsKey = @"OBAPushNotificationPushTokenDefaultsKey";

@interface OBAPushManager ()<OSSubscriptionObserver>

@end

@implementation OBAPushManager

#pragma mark - Permissions

+ (BOOL)isRegisteredForRemoteNotifications {
    return [OneSignal getPermissionSubscriptionState].permissionStatus.status == OSNotificationPermissionAuthorized;
}

#pragma mark - Setup Stuff

+ (instancetype)pushManager {

    static OBAPushManager *pushManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pushManager = [[OBAPushManager alloc] init];
    });
    return pushManager;
}

- (void)startWithLaunchOptions:(NSDictionary*)launchOptions delegate:(id<OBAPushManagerDelegate>)delegate APIKey:(NSString*)APIKey {
    self.delegate = delegate;
    [OneSignal addSubscriptionObserver:self];

    [OneSignal initWithLaunchOptions:launchOptions appId:APIKey handleNotificationAction:^(OSNotificationOpenedResult *result) {
        [self.delegate pushManager:self notificationReceivedWithTitle:@"Time to leave!" message:result.notification.payload.body data:result.notification.payload.additionalData];
    } settings:@{kOSSettingsKeyAutoPrompt: @(NO), kOSSettingsKeyInAppAlerts: @(YES)}];
}

#pragma mark - OneSignal Delegate Methods

- (void)onOSSubscriptionChanged:(OSSubscriptionStateChanges*)stateChanges {
    // TODO: send the updates to the server.
//    NSString *userID = stateChanges.to.userId;
//    NSString *pushToken = stateChanges.to.pushToken;
}

#pragma mark - Promises

- (AnyPromise*)requestUserPushNotificationID {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [OneSignal promptForPushNotificationsWithUserResponse:^(BOOL accepted) {
            if (accepted) {
                resolve([OneSignal getPermissionSubscriptionState].subscriptionStatus.userId);
            }
            else {
                resolve([NSError errorWithDomain:OBAErrorDomain code:OBAErrorCodePushNotificationAuthorizationDenied userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"push_manager.authorization_denied", @"Error message shown when the user denies the app the ability to send push notifications.")}]);
            }
        }];
    }];
}

#pragma mark - User Identity Tokens

- (NSString*)pushNotificationUserID {
    return [OneSignal getPermissionSubscriptionState].subscriptionStatus.userId;
}

- (NSString*)pushNotificationToken {
    return [OneSignal getPermissionSubscriptionState].subscriptionStatus.pushToken;
}

@end

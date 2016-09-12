//
//  ApptentiveEngagementBackend.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const ATEngagementInstallDateKey;
extern NSString *const ATEngagementUpgradeDateKey;
extern NSString *const ATEngagementLastUsedVersionKey;
extern NSString *const ATEngagementIsUpdateVersionKey;
extern NSString *const ATEngagementIsUpdateBuildKey;
extern NSString *const ATEngagementCodePointsInvokesTotalKey;
extern NSString *const ATEngagementCodePointsInvokesVersionKey;
extern NSString *const ATEngagementCodePointsInvokesBuildKey;
extern NSString *const ATEngagementCodePointsInvokesLastDateKey;
extern NSString *const ATEngagementInteractionsInvokesTotalKey;
extern NSString *const ATEngagementInteractionsInvokesVersionKey;
extern NSString *const ATEngagementInteractionsInvokesBuildKey;
extern NSString *const ATEngagementInteractionsInvokesLastDateKey;
extern NSString *const ATEngagementInteractionsSDKVersionKey;

extern NSString *const ATEngagementCodePointHostAppVendorKey;
extern NSString *const ATEngagementCodePointHostAppInteractionKey;
extern NSString *const ATEngagementCodePointApptentiveVendorKey;
extern NSString *const ATEngagementCodePointApptentiveAppInteractionKey;

extern NSString *const ApptentiveEngagementMessageCenterEvent;

@class ApptentiveInteraction;


@interface ApptentiveEngagementBackend : NSObject

- (void)checkForEngagementManifest;
- (BOOL)shouldRetrieveNewEngagementManifest;

- (void)didReceiveNewTargets:(NSDictionary *)targets andInteractions:(NSDictionary *)interactions maxAge:(NSTimeInterval)expiresMaxAge;

- (void)updateVersionInfo;
+ (NSString *)cachedTargetsStoragePath;
+ (NSString *)cachedInteractionsStoragePath;

- (ApptentiveInteraction *)interactionForEvent:(NSString *)event;

- (ApptentiveInteraction *)interactionForInvocations:(NSArray *)invocations;

- (BOOL)canShowInteractionForLocalEvent:(NSString *)event;
- (BOOL)canShowInteractionForCodePoint:(NSString *)codePoint;

+ (NSString *)stringByEscapingCodePointSeparatorCharactersInString:(NSString *)string;
+ (NSString *)codePointForVendor:(NSString *)vendor interactionType:(NSString *)interactionType event:(NSString *)event;

- (BOOL)engageApptentiveAppEvent:(NSString *)event;
- (BOOL)engageLocalEvent:(NSString *)event userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController;

- (BOOL)engageCodePoint:(NSString *)codePoint fromInteraction:(ApptentiveInteraction *)fromInteraction userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController;

- (void)codePointWasSeen:(NSString *)codePoint;
- (void)codePointWasEngaged:(NSString *)codePoint;
- (void)interactionWasSeen:(NSString *)interactionID;
- (void)interactionWasEngaged:(ApptentiveInteraction *)interaction;

- (void)presentInteraction:(ApptentiveInteraction *)interaction fromViewController:(UIViewController *)viewController;

// Used for debugging only.
@property (strong, nonatomic) NSURL *localEngagementManifestURL;
@property (copy, nonatomic) NSData *engagementManifestJSON;

- (void)resetUpgradeVersionInfo;
- (NSArray *)allEngagementInteractions;
- (NSArray<NSString *> *)targetedLocalEvents;

@end

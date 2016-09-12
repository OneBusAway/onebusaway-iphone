//
//  ApptentiveAppConfigurationUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveAPIRequest.h"

extern NSString *const ATConfigurationPreferencesChangedNotification;
extern NSString *const ATAppConfigurationExpirationPreferenceKey;
extern NSString *const ATAppConfigurationMetricsEnabledPreferenceKey;
extern NSString *const ATAppConfigurationHideBrandingKey;
extern NSString *const ATAppConfigurationNotificationPopupsEnabledKey;

extern NSString *const ATAppConfigurationMessageCenterForegroundRefreshIntervalKey;
extern NSString *const ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey;

extern NSString *const ATAppConfigurationAppDisplayNameKey;

@protocol ATAppConfigurationUpdaterDelegate <NSObject>
- (void)configurationUpdaterDidFinish:(BOOL)success;
@end


@interface ApptentiveAppConfigurationUpdater : NSObject <ApptentiveAPIRequestDelegate>

@property (weak, nonatomic) NSObject<ATAppConfigurationUpdaterDelegate> *delegate;

+ (BOOL)shouldCheckForUpdate;
- (id)initWithDelegate:(NSObject<ATAppConfigurationUpdaterDelegate> *)delegate;
- (void)update;
- (void)cancel;
- (float)percentageComplete;
@end

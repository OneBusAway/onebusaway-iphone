//
//  ApptentiveAppConfigurationUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAppConfigurationUpdater.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveWebClient.h"
#import "Apptentive_Private.h"

NSString *const ATConfigurationSDKVersionKey = @"ATConfigurationSDKVersionKey";
NSString *const ATConfigurationAppBuildNumberKey = @"ATConfigurationAppBuildNumberKey";

NSString *const ATConfigurationPreferencesChangedNotification = @"ATConfigurationPreferencesChangedNotification";
NSString *const ATAppConfigurationExpirationPreferenceKey = @"ATAppConfigurationExpirationPreferenceKey";
NSString *const ATAppConfigurationMetricsEnabledPreferenceKey = @"ATAppConfigurationMetricsEnabledPreferenceKey";
NSString *const ATAppConfigurationHideBrandingKey = @"ATAppConfigurationHideBrandingKey";
NSString *const ATAppConfigurationNotificationPopupsEnabledKey = @"ATAppConfigurationNotificationPopupsEnabledKey";

NSString *const ATAppConfigurationMessageCenterForegroundRefreshIntervalKey = @"ATAppConfigurationMessageCenterForegroundRefreshIntervalKey";
NSString *const ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey = @"ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey";

NSString *const ATAppConfigurationAppDisplayNameKey = @"ATAppConfigurationAppDisplayNameKey";


@interface ApptentiveAppConfigurationUpdater ()
- (void)processResult:(NSDictionary *)jsonRatingConfiguration maxAge:(NSTimeInterval)expiresMaxAge;
@end


@implementation ApptentiveAppConfigurationUpdater {
	ApptentiveAPIRequest *request;
}

+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences =
		[NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithBool:YES], ATAppConfigurationMetricsEnabledPreferenceKey,
					  [NSNumber numberWithInt:20], ATAppConfigurationMessageCenterForegroundRefreshIntervalKey,
					  [NSNumber numberWithInt:60], ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey,
					  [NSNumber numberWithBool:NO], ATAppConfigurationNotificationPopupsEnabledKey,
					  nil];
	[defaults registerDefaults:defaultPreferences];
}

+ (BOOL)invalidateAppConfigurationIfNeeded {
	BOOL invalidateCache = NO;

	NSString *previousBuild = [[NSUserDefaults standardUserDefaults] stringForKey:ATConfigurationAppBuildNumberKey];
	if (![previousBuild isEqualToString:[ApptentiveUtilities buildNumberString]]) {
		invalidateCache = YES;
	}

	NSString *previousSDKVersion = [[NSUserDefaults standardUserDefaults] stringForKey:ATConfigurationSDKVersionKey];
	if (![previousSDKVersion isEqualToString:kApptentiveVersionString]) {
		invalidateCache = YES;
	}

	if (invalidateCache) {
		[self invalidateAppConfiguration];
	}

	return invalidateCache;
}

+ (void)invalidateAppConfiguration {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATAppConfigurationExpirationPreferenceKey];
}

+ (BOOL)shouldCheckForUpdate {
	[ApptentiveAppConfigurationUpdater registerDefaults];

	[ApptentiveAppConfigurationUpdater invalidateAppConfigurationIfNeeded];

	NSDate *expiration = [[NSUserDefaults standardUserDefaults] objectForKey:ATAppConfigurationExpirationPreferenceKey];
	if (expiration) {
		NSComparisonResult comparison = [expiration compare:[NSDate date]];
		if (comparison == NSOrderedSame || comparison == NSOrderedAscending) {
			return YES;
		} else {
			return NO;
		}
	} else {
		return YES;
	}
}

- (id)initWithDelegate:(NSObject<ATAppConfigurationUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		_delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	[self cancel];
}

- (void)update {
	[self cancel];
	request = [[Apptentive sharedConnection].webClient requestForGettingAppConfiguration];
	request.delegate = self;
	[request start];
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		request = nil;
	}
}

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result maxAge:[sender expiresMaxAge]];
			[self.delegate configurationUpdaterDidFinish:YES];
		} else {
			ApptentiveLogError(@"App configuration result is not NSDictionary!");
			[self.delegate configurationUpdaterDidFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ApptentiveAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)sender {
	@synchronized(self) {
		ApptentiveLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);

		[self.delegate configurationUpdaterDidFinish:NO];
	}
}

#pragma mark - Private methods

- (void)processResult:(NSDictionary *)jsonConfiguration maxAge:(NSTimeInterval)expiresMaxAge {
	BOOL hasConfigurationChanges = NO;

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[ApptentiveAppConfigurationUpdater registerDefaults];

	NSDictionary *numberObjects =
		[NSDictionary dictionaryWithObjectsAndKeys:
						  @"metrics_enabled", ATAppConfigurationMetricsEnabledPreferenceKey,
					  @"hide_branding", ATAppConfigurationHideBrandingKey,
					  nil];

	NSArray *boolPreferences = [NSArray arrayWithObjects:@"ratings_clear_on_upgrade", @"ratings_enabled", @"metrics_enabled", @"message_center_enabled", @"hide_branding", nil];

	for (NSString *key in numberObjects) {
		NSObject *value = [jsonConfiguration objectForKey:[numberObjects objectForKey:key]];
		if (!value || ![value isKindOfClass:[NSNumber class]]) {
			continue;
		}

		NSNumber *numberValue = (NSNumber *)value;

		NSNumber *existingNumber = [defaults objectForKey:key];
		if ([existingNumber isEqualToNumber:numberValue]) {
			continue;
		}

		if ([boolPreferences containsObject:[numberObjects objectForKey:key]]) {
			[defaults setObject:numberValue forKey:key];
		} else {
			NSUInteger unsignedIntegerValue = [numberValue unsignedIntegerValue];
			NSNumber *replacementValue = [NSNumber numberWithUnsignedInteger:unsignedIntegerValue];

			[defaults setObject:replacementValue forKey:key];
		}
		hasConfigurationChanges = YES;
	}

	// Store expiration.
	if (expiresMaxAge > 0) {
		NSDate *date = [NSDate dateWithTimeInterval:expiresMaxAge sinceDate:[NSDate date]];
		[defaults setObject:date forKey:ATAppConfigurationExpirationPreferenceKey];
		[defaults synchronize];
	}

	if ([jsonConfiguration objectForKey:@"message_center"]) {
		NSObject *messageCenterConfiguration = [jsonConfiguration objectForKey:@"message_center"];
		if ([messageCenterConfiguration isKindOfClass:[NSDictionary class]]) {
			NSDictionary *mc = (NSDictionary *)messageCenterConfiguration;

			NSNumber *fgRefresh = [mc objectForKey:@"fg_poll"];
			NSNumber *oldFGRefresh = [defaults objectForKey:ATAppConfigurationMessageCenterForegroundRefreshIntervalKey];
			if (!oldFGRefresh || [oldFGRefresh intValue] != [fgRefresh intValue]) {
				[defaults setObject:fgRefresh forKey:ATAppConfigurationMessageCenterForegroundRefreshIntervalKey];
				hasConfigurationChanges = YES;
			}

			NSNumber *bgRefresh = [mc objectForKey:@"bg_poll"];
			NSNumber *oldBGRefresh = [defaults objectForKey:ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey];
			if (!oldBGRefresh || [oldBGRefresh intValue] != [bgRefresh intValue]) {
				[defaults setObject:bgRefresh forKey:ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey];
				hasConfigurationChanges = YES;
			}

			if ([mc objectForKey:@"notification_popup"]) {
				NSObject *notificationPopupConfiguration = [mc objectForKey:@"notification_popup"];
				if ([notificationPopupConfiguration isKindOfClass:[NSDictionary class]]) {
					NSDictionary *np = (NSDictionary *)notificationPopupConfiguration;

					NSNumber *npEnabled = [np objectForKey:@"enabled"];
					NSNumber *oldNPEnabled = [defaults objectForKey:ATAppConfigurationNotificationPopupsEnabledKey];
					if (!oldNPEnabled || oldNPEnabled.boolValue != npEnabled.boolValue) {
						[defaults setObject:npEnabled forKey:ATAppConfigurationNotificationPopupsEnabledKey];
						hasConfigurationChanges = YES;
					}
				}
			}
		}
	}

	BOOL setAppName = NO;
	if ([jsonConfiguration objectForKey:@"app_display_name"]) {
		NSObject *appNameObject = [jsonConfiguration objectForKey:@"app_display_name"];
		if ([appNameObject isKindOfClass:[NSString class]]) {
			[defaults setObject:appNameObject forKey:ATAppConfigurationAppDisplayNameKey];
			setAppName = YES;
		}
	}
	if (!setAppName) {
		[defaults removeObjectForKey:ATAppConfigurationAppDisplayNameKey];
	}

	[defaults setObject:kApptentiveVersionString forKey:ATConfigurationSDKVersionKey];
	[defaults setObject:[ApptentiveUtilities buildNumberString] forKey:ATConfigurationAppBuildNumberKey];

	if (hasConfigurationChanges) {
		[[NSNotificationCenter defaultCenter] postNotificationName:ATConfigurationPreferencesChangedNotification object:nil];
	}
}
@end

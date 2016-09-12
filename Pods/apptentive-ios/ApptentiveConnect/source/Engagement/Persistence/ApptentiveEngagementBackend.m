//
//  ApptentiveEngagementBackend.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEngagementBackend.h"
#import "ApptentiveBackend.h"
#import "ApptentiveEngagementGetManifestTask.h"
#import "ApptentiveEngagementManifestParser.h"
#import "ApptentiveTaskQueue.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionInvocation.h"
#import "Apptentive_Private.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveMetrics.h"
#import "ApptentiveInteractionUpgradeMessageViewController.h"
#import "ApptentiveInteractionEnjoymentDialogController.h"
#import "ApptentiveInteractionRatingDialogController.h"
#import "ApptentiveInteractionMessageCenterController.h"
#import "ApptentiveInteractionAppStoreController.h"
#import "ApptentiveInteractionSurveyController.h"
#import "ApptentiveInteractionTextModalController.h"
#import "ApptentiveInteractionNavigateToLink.h"
#import "ApptentiveInteractionController.h"

NSString *const ATEngagementInstallDateKey = @"ATEngagementInstallDateKey";
NSString *const ATEngagementUpgradeDateKey = @"ATEngagementUpgradeDateKey";
NSString *const ATEngagementLastUsedVersionKey = @"ATEngagementLastUsedVersionKey";
NSString *const ATEngagementIsUpdateVersionKey = @"ATEngagementIsUpdateVersionKey";
NSString *const ATEngagementIsUpdateBuildKey = @"ATEngagementIsUpdateBuildKey";
NSString *const ATEngagementCodePointsInvokesTotalKey = @"ATEngagementCodePointsInvokesTotalKey";
NSString *const ATEngagementCodePointsInvokesVersionKey = @"ATEngagementCodePointsInvokesVersionKey";
NSString *const ATEngagementCodePointsInvokesBuildKey = @"ATEngagementCodePointsInvokesBuildKey";
NSString *const ATEngagementCodePointsInvokesLastDateKey = @"ATEngagementCodePointsInvokesLastDateKey";
NSString *const ATEngagementInteractionsInvokesTotalKey = @"ATEngagementInteractionsInvokesTotalKey";
NSString *const ATEngagementInteractionsInvokesVersionKey = @"ATEngagementInteractionsInvokesVersionKey";
NSString *const ATEngagementInteractionsInvokesLastDateKey = @"ATEngagementInteractionsInvokesLastDateKey";
NSString *const ATEngagementInteractionsInvokesBuildKey = @"ATEngagementInteractionsInvokesBuildKey";

NSString *const ATEngagementInteractionsSDKVersionKey = @"ATEngagementInteractionsSDKVersionKey";
NSString *const ATEngagementInteractionsAppBuildNumberKey = @"ATEngagementInteractionsAppBuildNumberKey";
NSString *const ATEngagementCachedInteractionsExpirationPreferenceKey = @"ATEngagementCachedInteractionsExpirationPreferenceKey";

NSString *const ATEngagementCodePointHostAppVendorKey = @"local";
NSString *const ATEngagementCodePointHostAppInteractionKey = @"app";
NSString *const ATEngagementCodePointApptentiveVendorKey = @"com.apptentive";
NSString *const ATEngagementCodePointApptentiveAppInteractionKey = @"app";

NSString *const ApptentiveEngagementMessageCenterEvent = @"show_message_center";


@interface ApptentiveEngagementBackend ()

@property (strong, nonatomic) NSMutableDictionary *engagementTargets;
@property (strong, nonatomic) NSMutableDictionary *engagementInteractions;

@end


@implementation ApptentiveEngagementBackend

- (id)init {
	if ((self = [super init])) {
		NSDictionary *defaults = @{ ATEngagementIsUpdateVersionKey: @NO,
			ATEngagementIsUpdateBuildKey: @NO,
			ATEngagementCodePointsInvokesTotalKey: @{},
			ATEngagementCodePointsInvokesVersionKey: @{},
			ATEngagementCodePointsInvokesLastDateKey: @{},
			ATEngagementInteractionsInvokesTotalKey: @{},
			ATEngagementInteractionsInvokesVersionKey: @{},
			ATEngagementInteractionsInvokesLastDateKey: @{} };
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

		_engagementTargets = [[NSMutableDictionary alloc] init];
		_engagementInteractions = [[NSMutableDictionary alloc] init];

		[self loadCachedEngagementManifest];

		[self invalidateInteractionCacheIfNeeded];

		[self updateVersionInfo];
	}

	return self;
}

- (BOOL)invalidateInteractionCacheIfNeeded {
	BOOL invalidateCache = NO;

#if APPTENTIVE_DEBUG
	invalidateCache = YES;
#endif

	NSString *previousBuild = [[NSUserDefaults standardUserDefaults] stringForKey:ATEngagementInteractionsAppBuildNumberKey];
	if (![previousBuild isEqualToString:[ApptentiveUtilities buildNumberString]]) {
		invalidateCache = YES;
	}

	NSString *previousSDKVersion = [[NSUserDefaults standardUserDefaults] stringForKey:ATEngagementInteractionsSDKVersionKey];
	if (![previousSDKVersion isEqualToString:kApptentiveVersionString]) {
		invalidateCache = YES;
	}

	if (invalidateCache) {
		[self invalidateInteractionCache];
	}

	return invalidateCache;
}

- (void)invalidateInteractionCache {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];
}

- (void)checkForEngagementManifest {
	if (!self.localEngagementManifestURL && [self shouldRetrieveNewEngagementManifest]) {
		ApptentiveEngagementGetManifestTask *task = [[ApptentiveEngagementGetManifestTask alloc] init];
		[[ApptentiveTaskQueue sharedTaskQueue] addTask:task];
		task = nil;
	}
}

- (BOOL)shouldRetrieveNewEngagementManifest {
	NSDate *expiration = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];
	if (expiration) {
		NSDate *now = [NSDate date];
		NSComparisonResult comparison = [expiration compare:now];
		if (comparison == NSOrderedSame || comparison == NSOrderedAscending) {
			return YES;
		} else {
			NSFileManager *fm = [NSFileManager defaultManager];
			if (![fm fileExistsAtPath:[ApptentiveEngagementBackend cachedTargetsStoragePath]]) {
				return YES;
			}

			if (![fm fileExistsAtPath:[ApptentiveEngagementBackend cachedInteractionsStoragePath]]) {
				return YES;
			}

			return NO;
		}
	} else {
		return YES;
	}
}

- (void)didReceiveNewTargets:(NSDictionary *)targets andInteractions:(NSDictionary *)interactions maxAge:(NSTimeInterval)expiresMaxAge {
	if (!targets || !interactions) {
		ApptentiveLogError(@"Error receiving new Engagement Framework targets and interactions.");
		return;
	}

	ApptentiveLogInfo(@"Received remote Interactions from Apptentive.");

	@synchronized(self) {
		if ([[Apptentive sharedConnection].backend supportDirectoryPath]) {
			[NSKeyedArchiver archiveRootObject:targets toFile:[ApptentiveEngagementBackend cachedTargetsStoragePath]];
			[NSKeyedArchiver archiveRootObject:interactions toFile:[ApptentiveEngagementBackend cachedInteractionsStoragePath]];

			if (expiresMaxAge > 0) {
				NSDate *date = [NSDate dateWithTimeInterval:expiresMaxAge sinceDate:[NSDate date]];
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				[defaults setObject:date forKey:ATEngagementCachedInteractionsExpirationPreferenceKey];
			}

			[self.engagementTargets removeAllObjects];
			[self.engagementTargets addEntriesFromDictionary:targets];

			[self.engagementInteractions removeAllObjects];
			[self.engagementInteractions addEntriesFromDictionary:interactions];

			NSString *buildNumber = [ApptentiveUtilities buildNumberString];
			if ([ApptentiveUtilities buildNumberString]) {
				[[NSUserDefaults standardUserDefaults] setObject:buildNumber forKey:ATEngagementInteractionsAppBuildNumberKey];
			} else {
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInteractionsAppBuildNumberKey];
			}

			[[NSUserDefaults standardUserDefaults] setObject:kApptentiveVersionString forKey:ATEngagementInteractionsSDKVersionKey];

			[self updateVersionInfo];
		}
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsDidUpdateNotification object:nil];
}

- (void)updateVersionInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSDate *installDate = [defaults objectForKey:ATEngagementInstallDateKey];
	if (!installDate) {
		[defaults setObject:[NSDate date] forKey:ATEngagementInstallDateKey];
	}

	NSString *currentBundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
	NSString *lastBundleVersion = [defaults objectForKey:ATEngagementLastUsedVersionKey];

	// Both version and build are required (by iTunes Connect) to be updated upon App Store release.
	// If the bundle version has changed, we can mark both version and build as updated.
	if (lastBundleVersion && ![lastBundleVersion isEqualToString:currentBundleVersion]) {
		[defaults setObject:@YES forKey:ATEngagementIsUpdateVersionKey];
		[defaults setObject:@YES forKey:ATEngagementIsUpdateBuildKey];
	}

	if (lastBundleVersion == nil || ![lastBundleVersion isEqualToString:currentBundleVersion]) {
		[defaults setObject:currentBundleVersion forKey:ATEngagementLastUsedVersionKey];
		[defaults setObject:[NSDate date] forKey:ATEngagementUpgradeDateKey];
		[defaults setObject:@{} forKey:ATEngagementCodePointsInvokesVersionKey];
		[defaults setObject:@{} forKey:ATEngagementCodePointsInvokesBuildKey];
		[defaults setObject:@{} forKey:ATEngagementInteractionsInvokesVersionKey];
		[defaults setObject:@{} forKey:ATEngagementInteractionsInvokesBuildKey];
	}
}

+ (NSString *)cachedTargetsStoragePath {
	return [[[Apptentive sharedConnection].backend supportDirectoryPath] stringByAppendingPathComponent:@"cachedtargets.objects"];
}

+ (NSString *)cachedInteractionsStoragePath {
	return [[[Apptentive sharedConnection].backend supportDirectoryPath] stringByAppendingPathComponent:@"cachedinteractionsV2.objects"];
}

- (BOOL)canShowInteractionForLocalEvent:(NSString *)event {
	NSString *codePoint = [[ApptentiveInteraction localAppInteraction] codePointForEvent:event];

	return [self canShowInteractionForCodePoint:codePoint];
}

- (BOOL)canShowInteractionForCodePoint:(NSString *)codePoint {
	ApptentiveInteraction *interaction = [[Apptentive sharedConnection].engagementBackend interactionForEvent:codePoint];

	return (interaction != nil);
}

- (ApptentiveInteraction *)interactionForInvocations:(NSArray *)invocations {
	NSString *interactionID = nil;

	for (NSObject *invocationOrDictionary in invocations) {
		ApptentiveInteractionInvocation *invocation = nil;

		// Allow parsing of ATInteractionInvocation and NSDictionary invocation objects
		if ([invocationOrDictionary isKindOfClass:[ApptentiveInteractionInvocation class]]) {
			invocation = (ApptentiveInteractionInvocation *)invocationOrDictionary;
		} else if ([invocationOrDictionary isKindOfClass:[NSDictionary class]]) {
			invocation = [ApptentiveInteractionInvocation invocationWithJSONDictionary:((NSDictionary *)invocationOrDictionary)];
		} else {
			ApptentiveLogError(@"Attempting to parse an invocation that is neither an ATInteractionInvocation or NSDictionary.");
		}

		if (invocation && [invocation isKindOfClass:[ApptentiveInteractionInvocation class]]) {
			if ([invocation isValid]) {
				interactionID = invocation.interactionID;
				break;
			}
		}
	}

	ApptentiveInteraction *interaction = nil;
	if (interactionID) {
		interaction = self.engagementInteractions[interactionID];
	}

	return interaction;
}

- (ApptentiveInteraction *)interactionForEvent:(NSString *)event {
	NSArray *invocations = self.engagementTargets[event];
	ApptentiveInteraction *interaction = [self interactionForInvocations:invocations];

	return interaction;
}

+ (NSString *)stringByEscapingCodePointSeparatorCharactersInString:(NSString *)string {
	// Only escape "%", "/", and "#".
	// Do not change unless the server spec changes.
	NSMutableString *escape = [string mutableCopy];
	[escape replaceOccurrencesOfString:@"%" withString:@"%25" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];
	[escape replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];
	[escape replaceOccurrencesOfString:@"#" withString:@"%23" options:NSLiteralSearch range:NSMakeRange(0, escape.length)];

	return escape;
}

+ (NSString *)codePointForVendor:(NSString *)vendor interactionType:(NSString *)interactionType event:(NSString *)event {
	NSString *encodedVendor = [ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:vendor];
	NSString *encodedInteractionType = [ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:interactionType];
	NSString *encodedEvent = [ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:event];

	NSString *codePoint = [NSString stringWithFormat:@"%@#%@#%@", encodedVendor, encodedInteractionType, encodedEvent];

	return codePoint;
}

- (BOOL)engageApptentiveAppEvent:(NSString *)event {
	return [[ApptentiveInteraction apptentiveAppInteraction] engage:event fromViewController:nil];
}

- (BOOL)engageLocalEvent:(NSString *)event userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	return [[ApptentiveInteraction localAppInteraction] engage:event fromViewController:viewController userInfo:userInfo customData:customData extendedData:extendedData];
}

- (BOOL)engageCodePoint:(NSString *)codePoint fromInteraction:(ApptentiveInteraction *)fromInteraction userInfo:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	ApptentiveLogInfo(@"Engage Apptentive event: %@", codePoint);
	if (![[Apptentive sharedConnection].backend isReady]) {
		return NO;
	}

	[[ApptentiveMetrics sharedMetrics] addMetricWithName:codePoint fromInteraction:fromInteraction info:userInfo customData:customData extendedData:extendedData];

	[self codePointWasEngaged:codePoint];

	BOOL didEngageInteraction = NO;

	ApptentiveInteraction *interaction = [self interactionForEvent:codePoint];
	if (interaction) {
		ApptentiveLogInfo(@"--Running valid %@ interaction.", interaction.type);

		if (viewController == nil) {
			viewController = [[Apptentive sharedConnection] viewControllerForInteractions];
		}

		if (viewController == nil || !viewController.isViewLoaded || viewController.view.window == nil) {
			ApptentiveLogError(@"Attempting to present interaction on a view controller whose view is not visible in a window.");
			return NO;
		}

		[self presentInteraction:interaction fromViewController:viewController];

		[self interactionWasEngaged:interaction];
		didEngageInteraction = YES;

		// Sync defaults so user doesn't see interaction more than once.
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

	return didEngageInteraction;
}

- (void)codePointWasSeen:(NSString *)codePoint {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSDictionary *invokesTotal = [defaults objectForKey:ATEngagementCodePointsInvokesTotalKey];
	if (![invokesTotal objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesTotal];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[defaults setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesTotalKey];
	}

	NSDictionary *invokesVersion = [defaults objectForKey:ATEngagementCodePointsInvokesVersionKey];
	if (![invokesVersion objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesVersion];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[defaults setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesVersionKey];
	}

	NSDictionary *invokesBuild = [defaults objectForKey:ATEngagementCodePointsInvokesBuildKey];
	if (![invokesBuild objectForKey:codePoint]) {
		NSMutableDictionary *addedCodePoint = [NSMutableDictionary dictionaryWithDictionary:invokesBuild];
		[addedCodePoint setObject:@0 forKey:codePoint];
		[defaults setObject:addedCodePoint forKey:ATEngagementCodePointsInvokesBuildKey];
	}
}

- (void)codePointWasEngaged:(NSString *)codePoint {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSMutableDictionary *codePointsInvokesTotal = [[defaults objectForKey:ATEngagementCodePointsInvokesTotalKey] mutableCopy];
	NSNumber *codePointInvokesTotal = [codePointsInvokesTotal objectForKey:codePoint] ?: @0;
	codePointInvokesTotal = @(codePointInvokesTotal.intValue + 1);
	[codePointsInvokesTotal setObject:codePointInvokesTotal forKey:codePoint];
	[defaults setObject:codePointsInvokesTotal forKey:ATEngagementCodePointsInvokesTotalKey];

	NSMutableDictionary *codePointsInvokesVersion = [[defaults objectForKey:ATEngagementCodePointsInvokesVersionKey] mutableCopy];
	NSNumber *codePointInvokesVersion = [codePointsInvokesVersion objectForKey:codePoint] ?: @0;
	codePointInvokesVersion = @(codePointInvokesVersion.intValue + 1);
	[codePointsInvokesVersion setObject:codePointInvokesVersion forKey:codePoint];
	[defaults setObject:codePointsInvokesVersion forKey:ATEngagementCodePointsInvokesVersionKey];

	NSMutableDictionary *codePointsInvokesBuild = [[defaults objectForKey:ATEngagementCodePointsInvokesBuildKey] mutableCopy];
	NSNumber *codePointInvokesBuild = [codePointsInvokesBuild objectForKey:codePoint] ?: @0;
	codePointInvokesBuild = @(codePointInvokesBuild.intValue + 1);
	[codePointsInvokesBuild setObject:codePointInvokesBuild forKey:codePoint];
	[defaults setObject:codePointsInvokesBuild forKey:ATEngagementCodePointsInvokesBuildKey];

	NSMutableDictionary *codePointsInvokesTimeAgo = [[defaults objectForKey:ATEngagementCodePointsInvokesLastDateKey] mutableCopy];
	[codePointsInvokesTimeAgo setObject:[NSDate date] forKey:codePoint];
	[defaults setObject:codePointsInvokesTimeAgo forKey:ATEngagementCodePointsInvokesLastDateKey];
}

- (void)interactionWasSeen:(NSString *)interactionID {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSDictionary *invokesTotal = [defaults objectForKey:ATEngagementInteractionsInvokesTotalKey];
	if (![invokesTotal objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesTotal];
		[addedInteraction setObject:@0 forKey:interactionID];
		[defaults setObject:addedInteraction forKey:ATEngagementInteractionsInvokesTotalKey];
	}

	NSDictionary *invokesVersion = [defaults objectForKey:ATEngagementInteractionsInvokesVersionKey];
	if (![invokesVersion objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesVersion];
		[addedInteraction setObject:@0 forKey:interactionID];
		[defaults setObject:addedInteraction forKey:ATEngagementInteractionsInvokesVersionKey];
	}

	NSDictionary *invokesBuild = [defaults objectForKey:ATEngagementInteractionsInvokesBuildKey];
	if (![invokesBuild objectForKey:interactionID]) {
		NSMutableDictionary *addedInteraction = [NSMutableDictionary dictionaryWithDictionary:invokesBuild];
		[addedInteraction setObject:@0 forKey:interactionID];
		[defaults setObject:addedInteraction forKey:ATEngagementInteractionsInvokesBuildKey];
	}
}

- (void)interactionWasEngaged:(ApptentiveInteraction *)interaction {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSMutableDictionary *interactionsInvokesTotal = [[defaults objectForKey:ATEngagementInteractionsInvokesTotalKey] mutableCopy];
	NSNumber *interactionInvokesTotal = [interactionsInvokesTotal objectForKey:interaction.identifier] ?: @0;
	interactionInvokesTotal = @(interactionInvokesTotal.intValue + 1);
	[interactionsInvokesTotal setObject:interactionInvokesTotal forKey:interaction.identifier];
	[defaults setObject:interactionsInvokesTotal forKey:ATEngagementInteractionsInvokesTotalKey];

	NSMutableDictionary *interactionsInvokesVersion = [[defaults objectForKey:ATEngagementInteractionsInvokesVersionKey] mutableCopy];
	NSNumber *interactionInvokesVersion = [interactionsInvokesVersion objectForKey:interaction.identifier] ?: @0;
	interactionInvokesVersion = @(interactionInvokesVersion.intValue + 1);
	[interactionsInvokesVersion setObject:interactionInvokesVersion forKey:interaction.identifier];
	[defaults setObject:interactionsInvokesVersion forKey:ATEngagementInteractionsInvokesVersionKey];

	NSMutableDictionary *interactionsInvokesBuild = [[defaults objectForKey:ATEngagementInteractionsInvokesBuildKey] mutableCopy];
	NSNumber *interactionInvokesBuild = [interactionsInvokesBuild objectForKey:interaction.identifier] ?: @0;
	interactionInvokesBuild = @(interactionInvokesBuild.intValue + 1);
	[interactionsInvokesBuild setObject:interactionInvokesBuild forKey:interaction.identifier];
	[defaults setObject:interactionsInvokesBuild forKey:ATEngagementInteractionsInvokesBuildKey];

	NSMutableDictionary *interactionsInvokesLastDate = [[defaults objectForKey:ATEngagementInteractionsInvokesLastDateKey] mutableCopy];
	[interactionsInvokesLastDate setObject:[NSDate date] forKey:interaction.identifier];
	[defaults setObject:interactionsInvokesLastDate forKey:ATEngagementInteractionsInvokesLastDateKey];
}

- (void)presentInteraction:(ApptentiveInteraction *)interaction fromViewController:(UIViewController *)viewController {
	if (!interaction) {
		ApptentiveLogError(@"Attempting to present an interaction that does not exist!");
		return;
	}

	if (![[NSThread currentThread] isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self presentInteraction:interaction fromViewController:viewController];
		});
		return;
	}

	if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
		// Only present interaction UI in Active state.
		return;
	}

	ApptentiveInteractionController *controller = [ApptentiveInteractionController interactionControllerWithInteraction:interaction];

	[controller presentInteractionFromViewController:viewController];
}

- (void)resetUpgradeVersionInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:ATEngagementLastUsedVersionKey];
	[defaults removeObjectForKey:ATEngagementUpgradeDateKey];
	[defaults setObject:@{} forKey:ATEngagementCodePointsInvokesVersionKey];
	[defaults setObject:@{} forKey:ATEngagementInteractionsInvokesVersionKey];
	[defaults synchronize];
}

- (NSArray *)allEngagementInteractions {
	return [self.engagementInteractions allValues];
}

- (NSArray *)targetedLocalEvents {
	NSArray *localCodePoints = [self.engagementTargets.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] %@", @"local#app#"]];
	NSMutableArray *eventNames = [NSMutableArray array];
	for (NSString *codePoint in localCodePoints) {
		[eventNames addObject:[codePoint substringFromIndex:10]];
	}

	return eventNames;
}

- (void)setLocalEngagementManifestURL:(NSURL *)localEngagementManifestURL {
	if (_localEngagementManifestURL != localEngagementManifestURL) {
		_localEngagementManifestURL = localEngagementManifestURL;

		if (localEngagementManifestURL == nil) {
			[self loadCachedEngagementManifest];
			[self checkForEngagementManifest];
			[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsDidUpdateNotification object:nil];
		} else {
			[[ApptentiveTaskQueue sharedTaskQueue] removeTasksOfClass:[ApptentiveEngagementGetManifestTask class]];

			NSData *localData = [NSData dataWithContentsOfURL:localEngagementManifestURL];

			ApptentiveEngagementManifestParser *parser = [[ApptentiveEngagementManifestParser alloc] init];

			NSDictionary *targetsAndInteractions = [parser targetsAndInteractionsForEngagementManifest:localData];
			NSDictionary *targets = targetsAndInteractions[@"targets"];
			NSDictionary *interactions = targetsAndInteractions[@"interactions"];

			if (targets && interactions) {
				[self.engagementTargets removeAllObjects];
				[self.engagementTargets addEntriesFromDictionary:targets];

				[self.engagementInteractions removeAllObjects];
				[self.engagementInteractions addEntriesFromDictionary:interactions];

				[Apptentive sharedConnection].engagementBackend.engagementManifestJSON = targetsAndInteractions[@"raw"];
			} else {
				ApptentiveLogError(@"An error occurred parsing the engagement manifest: %@", [parser parserError]);
			}
		}
	}
}

- (void)loadCachedEngagementManifest {
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:[ApptentiveEngagementBackend cachedTargetsStoragePath]]) {
		@try {
			NSDictionary *archivedTargets = [NSKeyedUnarchiver unarchiveObjectWithFile:[ApptentiveEngagementBackend cachedTargetsStoragePath]];
			[_engagementTargets addEntriesFromDictionary:archivedTargets];
		} @catch (NSException *exception) {
			ApptentiveLogError(@"Unable to unarchive engagement targets: %@", exception);
		}
	}

	_engagementInteractions = [[NSMutableDictionary alloc] init];
	if ([fm fileExistsAtPath:[ApptentiveEngagementBackend cachedInteractionsStoragePath]]) {
		@try {
			NSDictionary *archivedInteractions = [NSKeyedUnarchiver unarchiveObjectWithFile:[ApptentiveEngagementBackend cachedInteractionsStoragePath]];
			[_engagementInteractions addEntriesFromDictionary:archivedInteractions];
		} @catch (NSException *exception) {
			ApptentiveLogError(@"Unable to unarchive engagement interactions: %@", exception);
		}
	}
}

@end

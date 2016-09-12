//
//  ApptentiveEngagementGetManifestTask.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEngagementGetManifestTask.h"
#import "ApptentiveBackend.h"
#import "ApptentiveDeviceUpdater.h"
#import "ApptentiveWebClient+EngagementAdditions.h"
#import "ApptentiveEngagementManifestParser.h"
#import "ApptentiveEngagementBackend.h"
#import "Apptentive_Private.h"


@implementation ApptentiveEngagementGetManifestTask {
	ApptentiveAPIRequest *checkManifestRequest;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
}

- (void)dealloc {
	[self stop];
}

- (BOOL)canStart {
	if ([Apptentive sharedConnection].webClient == nil) {
		ApptentiveLogDebug(@"Failed to download Apptentive configuration because API key is not set!");
		return NO;
	}
	if (![ApptentiveConversationUpdater conversationExists]) {
		return NO;
	}
	if ([ApptentiveDeviceUpdater shouldUpdate]) {
		// Interactions may depend on device attributes.
		return NO;
	}

	return YES;
}

- (BOOL)shouldArchive {
	return NO;
}

- (void)start {
	if (checkManifestRequest == nil) {
		ApptentiveWebClient *client = [Apptentive sharedConnection].webClient;
		checkManifestRequest = [client requestForGettingEngagementManifest];
		checkManifestRequest.delegate = self;
		self.inProgress = YES;
		[checkManifestRequest start];
	} else {
		self.finished = YES;
	}
}

- (void)stop {
	if (checkManifestRequest) {
		checkManifestRequest.delegate = nil;
		[checkManifestRequest cancel];
		checkManifestRequest = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (checkManifestRequest) {
		return [checkManifestRequest percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"engagement manifest check";
}

#pragma mark ApptentiveAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)request result:(NSObject *)result {
	@synchronized(self) {
		if (request == checkManifestRequest) {
			ApptentiveEngagementManifestParser *parser = [[ApptentiveEngagementManifestParser alloc] init];

			NSDictionary *targetsAndInteractions = [parser targetsAndInteractionsForEngagementManifest:(NSData *)result];
			NSDictionary *targets = targetsAndInteractions[@"targets"];
			NSDictionary *interactions = targetsAndInteractions[@"interactions"];

			if (targets && interactions) {
				[[Apptentive sharedConnection].engagementBackend didReceiveNewTargets:targets andInteractions:interactions maxAge:[request expiresMaxAge]];
				[Apptentive sharedConnection].engagementBackend.engagementManifestJSON = targetsAndInteractions[@"raw"];
			} else {
				ApptentiveLogError(@"An error occurred parsing the engagement manifest: %@", [parser parserError]);
			}

			checkManifestRequest.delegate = nil;
			checkManifestRequest = nil;
			parser = nil;
			self.finished = YES;
		}
	}
}

- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)request {
	@synchronized(self) {
		if (request == checkManifestRequest) {
			ApptentiveLogError(@"Engagement manifest request failed: %@: %@", request.errorTitle, request.errorMessage);
			self.lastErrorTitle = request.errorTitle;
			self.lastErrorMessage = request.errorMessage;
			self.failed = YES;
			[self stop];
		}
	}
}
@end

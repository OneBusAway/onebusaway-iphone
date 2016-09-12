//
//  ApptentiveSurveyResponseTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyResponseTask.h"
#import "ApptentiveBackend.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveWebClient+SurveyAdditions.h"
#import "Apptentive_Private.h"

#define kATPendingMessageTaskCodingVersion 1


@interface ApptentiveSurveyResponseTask ()
- (BOOL)processResult:(NSDictionary *)jsonMessage;

@property (strong, nonatomic) ApptentiveAPIRequest *request;

@end


@implementation ApptentiveSurveyResponseTask

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATSurveyResponseTask"];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATPendingMessageTaskCodingVersion) {
			self.pendingSurveyResponseID = [coder decodeObjectForKey:@"pendingSurveyResponseID"];
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPendingMessageTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.pendingSurveyResponseID forKey:@"pendingSurveyResponseID"];
}

- (void)dealloc {
	[self stop];
}

- (BOOL)canStart {
	if ([Apptentive sharedConnection].webClient == nil) {
		return NO;
	}
	if (![ApptentiveConversationUpdater conversationExists]) {
		return NO;
	}
	return YES;
}

- (void)start {
	if (!self.request) {
		ApptentiveSurveyResponse *response = [ApptentiveSurveyResponse findSurveyResponseWithPendingID:self.pendingSurveyResponseID];
		if (response == nil) {
			ApptentiveLogError(@"Warning: Response was nil in survey response task.");
			self.finished = YES;
			return;
		}
		self.request = [[Apptentive sharedConnection].webClient requestForPostingSurveyResponse:response];
		if (self.request != nil) {
			self.request.delegate = self;
			[self.request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
		response = nil;
	}
}

- (void)stop {
	if (self.request) {
		self.request.delegate = nil;
		[self.request cancel];
		self.request = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (self.request) {
		return [self.request percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"survey response";
}

#pragma mark ApptentiveAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		if ([result isKindOfClass:[NSDictionary class]] && [self processResult:(NSDictionary *)result]) {
			self.finished = YES;
		} else {
			ApptentiveLogError(@"Survey response result is not NSDictionary!");
			self.failed = YES;
		}
		[self stop];
	}
}

- (void)at_APIRequestDidProgress:(ApptentiveAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)sender {
	@synchronized(self) {
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;

		ApptentiveSurveyResponse *response = [ApptentiveSurveyResponse findSurveyResponseWithPendingID:self.pendingSurveyResponseID];
		if (response == nil) {
			ApptentiveLogError(@"Warning: Survey response went away during task.");
			self.finished = YES;
			return;
		}

		if (sender.errorResponse != nil) {
			NSError *parseError = nil;
			NSObject *errorObject = [ApptentiveJSONSerialization JSONObjectWithString:sender.errorResponse error:&parseError];
			if (errorObject != nil && [errorObject isKindOfClass:[NSDictionary class]]) {
				NSDictionary *errorDictionary = (NSDictionary *)errorObject;
				if ([errorDictionary objectForKey:@"errors"]) {
					ApptentiveLogInfo(@"ApptentiveAPIRequest server error: %@", [errorDictionary objectForKey:@"errors"]);
				}
			} else if (errorObject == nil) {
				ApptentiveLogError(@"Error decoding error response: %@", parseError);
			}
			[response setPendingState:@(ATPendingSurveyResponseError)];
		}
		NSError *error = nil;
		NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
		if (![context save:&error]) {
			ApptentiveLogError(@"Failed to save survey response after API failure: %@", error);
		}
		ApptentiveLogInfo(@"ApptentiveAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		if (self.failureCount > 2) {
			self.finished = YES;
		} else {
			self.failed = YES;
		}
		[self stop];
		response = nil;
	}
}

#pragma mark - Private methods

- (BOOL)processResult:(NSDictionary *)jsonResponse {
	ApptentiveLogDebug(@"Getting json result: %@", jsonResponse);
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];

	ApptentiveSurveyResponse *response = [ApptentiveSurveyResponse findSurveyResponseWithPendingID:self.pendingSurveyResponseID];
	if (response == nil) {
		ApptentiveLogError(@"Warning: Response went away during task.");
		return YES;
	}
	[response updateWithJSON:jsonResponse];
	response.pendingState = [NSNumber numberWithInt:ATPendingSurveyResponseConfirmed];

	NSError *error = nil;
	if (![context save:&error]) {
		ApptentiveLogError(@"Failed to save new response: %@", error);
		response = nil;
		return NO;
	}
	response = nil;
	return YES;
}
@end

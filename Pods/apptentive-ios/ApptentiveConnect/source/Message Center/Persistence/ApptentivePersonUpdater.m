//
//  ApptentivePersonUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePersonUpdater.h"

#import "ApptentiveConversationUpdater.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveWebClient+MessageCenter.h"
#import "Apptentive_Private.h"

NSString *const ATPersonLastUpdateValuePreferenceKey = @"ATPersonLastUpdateValuePreferenceKey";


@interface ApptentivePersonUpdater ()

@property (copy, nonatomic) NSDictionary *sentPersonJSON;
@property (strong, nonatomic) ApptentiveAPIRequest *request;

@end


@implementation ApptentivePersonUpdater

- (id)initWithDelegate:(NSObject<ATPersonUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		[ApptentivePersonUpdater registerDefaults];
		_delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	_delegate = nil;
	[self cancel];
}

+ (BOOL)shouldUpdate {
	[ApptentivePersonUpdater registerDefaults];

	return [[ApptentivePersonInfo currentPerson] apiJSON].count > 0;
}

+ (NSDictionary *)lastSavedVersion {
	NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:ATPersonLastUpdateValuePreferenceKey];

	if (data) {
		NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		if ([dictionary isKindOfClass:[NSDictionary class]]) {
			return dictionary;
		}
	}

	return nil;
}

- (void)saveVersion {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.sentPersonJSON];
	[[NSUserDefaults standardUserDefaults] setObject:data forKey:ATPersonLastUpdateValuePreferenceKey];
	self.sentPersonJSON = nil;
}

- (void)update {
	[self cancel];
	ApptentivePersonInfo *person = [ApptentivePersonInfo currentPerson];
	self.sentPersonJSON = person.dictionaryRepresentation;
	self.request = [[Apptentive sharedConnection].webClient requestForUpdatingPerson:person];
	self.request.delegate = self;
	[self.request start];
}

- (void)cancel {
	if (self.request) {
		self.request.delegate = nil;
		[self.request cancel];
		self.request = nil;
	}
}

- (float)percentageComplete {
	if (self.request) {
		return [self.request percentageComplete];
	} else {
		return 0.0f;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			ApptentiveLogError(@"Person result is not NSDictionary!");
			[self.delegate personUpdater:self didFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ApptentiveAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)sender {
	@synchronized(self) {
		ApptentiveLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);

		[self.delegate personUpdater:self didFinish:NO];
	}
}

#pragma mark - Private

+ (void)registerDefaults {
	NSDictionary *defaultPreferences = @{ ATPersonLastUpdateValuePreferenceKey: @{} };

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
}

- (void)processResult:(NSDictionary *)jsonPerson {
	ApptentivePersonInfo *person = [ApptentivePersonInfo newPersonFromJSON:jsonPerson];

	if (person) {
		// Save out the value we sent to the server.
		[self saveVersion];

		[self.delegate personUpdater:self didFinish:YES];
	} else {
		[self.delegate personUpdater:self didFinish:NO];
	}
	person = nil;
}
@end

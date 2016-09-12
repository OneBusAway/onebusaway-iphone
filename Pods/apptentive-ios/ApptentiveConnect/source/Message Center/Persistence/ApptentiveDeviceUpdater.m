//
//  ApptentiveDeviceUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDeviceUpdater.h"

#import "ApptentiveConversationUpdater.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveWebClient+MessageCenter.h"
#import "Apptentive_Private.h"


NSString *const ATDeviceLastUpdatePreferenceKey = @"ATDeviceLastUpdatePreferenceKey";
NSString *const ATDeviceLastUpdateValuePreferenceKey = @"ATDeviceLastUpdateValuePreferenceKey";


@interface ApptentiveDeviceUpdater ()

@property (copy, nonatomic) NSDictionary *sentDeviceJSON;
@property (strong, nonatomic) ApptentiveAPIRequest *request;

@end


@implementation ApptentiveDeviceUpdater

+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences =
		[NSDictionary dictionaryWithObjectsAndKeys:
						  [NSDate distantPast], ATDeviceLastUpdatePreferenceKey,
					  [NSDictionary dictionary], ATDeviceLastUpdateValuePreferenceKey,
					  nil];
	[defaults registerDefaults:defaultPreferences];
}

+ (BOOL)shouldUpdate {
	[ApptentiveDeviceUpdater registerDefaults];

	ApptentiveDeviceInfo *deviceInfo = [[ApptentiveDeviceInfo alloc] init];
	NSDictionary *deviceDictionary = [deviceInfo.apiJSON valueForKey:@"device"];

	return deviceDictionary.count > 0;
}

+ (NSDictionary *)lastSavedVersion {
	return [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATDeviceLastUpdateValuePreferenceKey];
}

- (id)initWithDelegate:(NSObject<ATDeviceUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		_delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	_delegate = nil;
	[self cancel];
}

- (void)update {
	[self cancel];
	ApptentiveDeviceInfo *deviceInfo = [[ApptentiveDeviceInfo alloc] init];
	self.sentDeviceJSON = deviceInfo.dictionaryRepresentation;
	self.request = [[Apptentive sharedConnection].webClient requestForUpdatingDevice:deviceInfo];
	self.request.delegate = self;
	[self.request start];
	deviceInfo = nil;
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
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

		[defaults setObject:[NSDate date] forKey:ATDeviceLastUpdatePreferenceKey];
		[defaults setObject:self.sentDeviceJSON forKey:ATDeviceLastUpdateValuePreferenceKey];
		[self.delegate deviceUpdater:self didFinish:YES];
	}
}

- (void)at_APIRequestDidProgress:(ApptentiveAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)sender {
	@synchronized(self) {
		ApptentiveLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);

		[self.delegate deviceUpdater:self didFinish:NO];
	}
}

@end

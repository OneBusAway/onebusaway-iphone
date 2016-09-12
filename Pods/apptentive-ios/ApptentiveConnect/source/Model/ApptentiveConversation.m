//
//  ApptentiveConversation.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversation.h"

#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveUtilities.h"
#import "NSDictionary+Apptentive.h"

#define kATConversationCodingVersion 1


@implementation ApptentiveConversation

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATConversation"];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		// Apptentive Conversation Token
		self.token = (NSString *)[coder decodeObjectForKey:@"token"];
		self.personID = (NSString *)[coder decodeObjectForKey:@"personID"];
		self.deviceID = (NSString *)[coder decodeObjectForKey:@"deviceID"];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATConversationCodingVersion forKey:@"version"];

	[coder encodeObject:self.token forKey:@"token"];
	[coder encodeObject:self.personID forKey:@"personID"];
	[coder encodeObject:self.deviceID forKey:@"deviceID"];
}

+ (instancetype)newInstanceWithJSON:(NSDictionary *)json {
	ApptentiveConversation *result = nil;

	if (json != nil) {
		result = [[ApptentiveConversation alloc] init];
		[result updateWithJSON:json];
	} else {
		ApptentiveLogError(@"Conversation JSON was nil");
	}

	return result;
}

- (void)updateWithJSON:(NSDictionary *)json {
	NSString *tokenObject = [json at_safeObjectForKey:@"token"];
	if (tokenObject != nil) {
		self.token = tokenObject;
	}
	NSString *deviceIDObject = [json at_safeObjectForKey:@"device_id"];
	if (deviceIDObject != nil) {
		self.deviceID = deviceIDObject;
	}
	NSString *personIDObject = [json at_safeObjectForKey:@"person_id"];
	if (personIDObject != nil) {
		self.personID = personIDObject;
	}
}

//TODO: Add support for sending person.
- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	NSString *deviceUUID = [[Apptentive sharedConnection].backend deviceUUID];
	if (deviceUUID) {
		NSDictionary *deviceInfo = @{ @"uuid": deviceUUID };
		result[@"device"] = deviceInfo;
	}
	result[@"app_release"] = [self appReleaseJSON];
	result[@"sdk"] = [self sdkJSON];

	return result;
}

- (NSDictionary *)appReleaseJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	NSString *appVersion = [ApptentiveUtilities appVersionString];
	if (appVersion) {
		result[@"version"] = appVersion;
	}

	NSString *buildNumber = [ApptentiveUtilities buildNumberString];
	if (buildNumber) {
		result[@"build_number"] = buildNumber;
	}

	NSString *appStoreReceiptFileName = [ApptentiveUtilities appStoreReceiptFileName];
	if (appStoreReceiptFileName) {
		NSDictionary *receiptInfo = @{ @"file_name": appStoreReceiptFileName,
			@"has_receipt": @([ApptentiveUtilities appStoreReceiptExists]),
		};

		result[@"app_store_receipt"] = receiptInfo;
	}

	result[@"overriding_styles"] = @([Apptentive sharedConnection].didAccessStyleSheet);

	return result;
}

- (NSDictionary *)sdkJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	result[@"version"] = kApptentiveVersionString;
	result[@"programming_language"] = @"Objective-C";
	result[@"author_name"] = @"Apptentive, Inc.";
	result[@"platform"] = kApptentivePlatformString;
	NSString *distribution = [[Apptentive sharedConnection].backend distributionName];
	if (distribution) {
		result[@"distribution"] = distribution;
	}
	NSString *distributionVersion = [[Apptentive sharedConnection].backend distributionVersion];
	if (distributionVersion) {
		result[@"distribution_version"] = distributionVersion;
	}

	return result;
}

- (NSDictionary *)apiUpdateJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	result[@"app_release"] = [self appReleaseJSON];
	result[@"sdk"] = [self sdkJSON];
	return result;
}
@end

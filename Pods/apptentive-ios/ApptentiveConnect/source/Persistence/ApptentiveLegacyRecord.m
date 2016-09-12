//
//  ApptentiveLegacyRecord.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacyRecord.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveUtilities.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#define kRecordCodingVersion 1


@interface ApptentiveLegacyRecord ()
- (NSString *)primaryLocale;
- (NSArray *)availableLocales;
@end


@implementation ApptentiveLegacyRecord

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATLegacyRecord"];
}

- (id)init {
	if ((self = [super init])) {
		self.uuid = [[Apptentive sharedConnection].backend deviceUUID];
		self.model = [[UIDevice currentDevice] model];
		self.os_version = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
		if ([CTTelephonyNetworkInfo class]) {
			CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
			CTCarrier *c = [netInfo subscriberCellularProvider];
			if (c.carrierName) {
				self.carrier = c.carrierName;
			}
		}
		self.date = [NSDate date];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [self init])) {
		int version = 0;
		BOOL hasVersion = YES;
		if ([coder containsValueForKey:@"record_version"]) {
			version = [coder decodeIntForKey:@"record_version"];
		} else {
			version = [coder decodeIntForKey:@"version"];
			hasVersion = NO;
		}
		if ((hasVersion == NO && (version == 1 || version == 2)) || hasVersion) {
			self.uuid = [coder decodeObjectForKey:@"uuid"];
			self.model = [coder decodeObjectForKey:@"model"];
			self.os_version = [coder decodeObjectForKey:@"os_version"];
			self.carrier = [coder decodeObjectForKey:@"carrier"];
			if ([coder containsValueForKey:@"date"]) {
				self.date = [coder decodeObjectForKey:@"date"];
			}
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kRecordCodingVersion forKey:@"record_version"];
	[coder encodeObject:self.uuid forKey:@"uuid"];
	[coder encodeObject:self.model forKey:@"model"];
	[coder encodeObject:self.os_version forKey:@"os_version"];
	[coder encodeObject:self.carrier forKey:@"carrier"];
	[coder encodeObject:self.date forKey:@"date"];
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	NSMutableDictionary *record = [NSMutableDictionary dictionary];
	NSMutableDictionary *device = [NSMutableDictionary dictionary];
	if (self.uuid) [device setObject:self.uuid forKey:@"uuid"];
	if (self.model) [device setObject:self.model forKey:@"model"];
	if (self.os_version) [device setObject:self.os_version forKey:@"os_version"];
	if (self.carrier) [device setObject:self.carrier forKey:@"carrier"];

	[record setObject:device forKey:@"device"];

	[record setObject:[self formattedDate:self.date] forKey:@"date"];

	// Add some client information.
	NSMutableDictionary *client = [NSMutableDictionary dictionary];
	[client setObject:kApptentiveVersionString forKey:@"version"];
	[client setObject:kApptentivePlatformString forKey:@"os"];
	[client setObject:@"Apptentive, Inc." forKey:@"author"];
	NSString *distribution = [[Apptentive sharedConnection].backend distributionName];
	if (distribution) {
		[client setObject:distribution forKey:@"distribution"];
	}
	NSString *distributionVersion = [[Apptentive sharedConnection].backend distributionVersion];
	if (distributionVersion) {
		[client setObject:distributionVersion forKey:@"distribution_version"];
	}
	[record setObject:client forKey:@"client"];
	[d setObject:record forKey:@"record"];

	// Add some app information.
	NSMutableDictionary *appVersion = [NSMutableDictionary dictionary];
	[appVersion setObject:[ApptentiveUtilities appVersionString] forKey:@"version"];
	NSString *buildNumber = [ApptentiveUtilities buildNumberString];
	if (buildNumber) {
		[appVersion setObject:buildNumber forKey:@"build_number"];
	}
	[appVersion setObject:[self primaryLocale] forKey:@"primary_locale"];
	[appVersion setObject:[self availableLocales] forKey:@"supported_locales"];
	[d setObject:appVersion forKey:@"app_version"];
	return d;
}

- (NSDictionary *)apiDictionary {
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	if (self.uuid) [d setObject:self.uuid forKey:@"record[device][uuid]"];
	if (self.model) [d setObject:self.model forKey:@"record[device][model]"];
	if (self.os_version) [d setObject:self.os_version forKey:@"record[device][os_version]"];
	if (self.carrier) [d setObject:self.carrier forKey:@"record[device][carrier]"];

	[d setObject:[self formattedDate:self.date] forKey:@"record[date]"];

	// Add some client information.
	[d setObject:kApptentiveVersionString forKey:@"record[client][version]"];
	[d setObject:kApptentivePlatformString forKey:@"record[client][os]"];
	[d setObject:@"Apptentive, Inc." forKey:@"record[client][author]"];
	NSString *distribution = [[Apptentive sharedConnection].backend distributionName];
	if (distribution) {
		[d setObject:distribution forKey:@"record[client][distribution]"];
	}
	NSString *distributionVersion = [[Apptentive sharedConnection].backend distributionVersion];
	if (distributionVersion) {
		[d setObject:distributionVersion forKey:@"record[client][distribution_version]"];
	}

	// Add some app information.
	[d setObject:[ApptentiveUtilities appVersionString] forKey:@"record[app_version][version]"];
	NSString *buildNumber = [ApptentiveUtilities buildNumberString];
	if (buildNumber) {
		[d setObject:buildNumber forKey:@"record[app_version][build_number]"];
	}
	[d setObject:[self primaryLocale] forKey:@"record[app_version][primary_locale]"];
	for (NSString *locale in [self availableLocales]) {
		[d setObject:locale forKey:@"record[app_version][supported_locales][]"];
	}

	return d;
}

- (NSString *)formattedDate:(NSDate *)aDate {
	return [ApptentiveUtilities stringRepresentationOfDate:aDate];
}

- (ApptentiveAPIRequest *)requestForSendingRecord {
	return nil;
}

- (void)cleanup {
	// Do nothing by default.
}

#pragma mark - Private methods

- (NSString *)primaryLocale {
	return [[NSLocale currentLocale] localeIdentifier];
}

- (NSArray *)availableLocales {
	return [ApptentiveUtilities availableAppLocalizations];
}
@end

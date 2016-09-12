//
//  ApptentiveDeviceInfo.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "ApptentiveDeviceInfo.h"
#import "ApptentiveBackend.h"
#import "Apptentive.h"
#import "Apptentive_Private.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveDeviceUpdater.h"


@implementation ApptentiveDeviceInfo
- (id)init {
	if ((self = [super init])) {
	}
	return self;
}


+ (NSString *)carrier {
	NSString *result = nil;
	if ([CTTelephonyNetworkInfo class]) {
		CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
		CTCarrier *c = [netInfo subscriberCellularProvider];
		if (c.carrierName) {
			result = c.carrierName;
		}
		netInfo = nil;
	}
	return result;
}

- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *device = [NSMutableDictionary dictionary];

	NSString *uuid = [[Apptentive sharedConnection].backend deviceUUID];
	if (uuid) {
		device[@"uuid"] = uuid;
	}

	NSString *osName = [ApptentiveUtilities currentSystemName];
	if (osName) {
		device[@"os_name"] = osName;
	}

	NSString *osVersion = [ApptentiveUtilities currentSystemVersion];
	if (osVersion) {
		device[@"os_version"] = osVersion;
	}

	NSString *systemBuild = [ApptentiveUtilities currentSystemBuild];
	if (systemBuild) {
		device[@"os_build"] = systemBuild;
	}

	NSString *machineName = [ApptentiveUtilities currentMachineName];
	if (machineName) {
		device[@"hardware"] = machineName;
	}

	NSString *contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
	if (contentSizeCategory) {
		device[@"content_size_category"] = contentSizeCategory;
	}

	NSString *carrier = [ApptentiveDeviceInfo carrier];
	if (carrier != nil) {
		device[@"carrier"] = carrier;
	}

	NSLocale *locale = [NSLocale currentLocale];
	NSString *localeIdentifier = [locale localeIdentifier];
	NSDictionary *localeComponents = [NSLocale componentsFromLocaleIdentifier:localeIdentifier];
	NSString *countryCode = [localeComponents objectForKey:NSLocaleCountryCode];
	if (localeIdentifier) {
		device[@"locale_raw"] = localeIdentifier;
	}
	if (countryCode) {
		device[@"locale_country_code"] = countryCode;
	}

	NSString *preferredLanguage = [[NSLocale preferredLanguages] firstObject];
	if (preferredLanguage) {
		device[@"locale_language_code"] = preferredLanguage;
	}

	device[@"utc_offset"] = @([[NSTimeZone systemTimeZone] secondsFromGMT]);

	NSDictionary *extraInfo = [[Apptentive sharedConnection] customDeviceData];
	if (extraInfo && [extraInfo count]) {
		device[@"custom_data"] = extraInfo;
	}

	NSDictionary *integrationConfiguration = [[Apptentive sharedConnection] integrationConfiguration];
	if (integrationConfiguration && [integrationConfiguration isKindOfClass:[NSDictionary class]]) {
		device[@"integration_config"] = integrationConfiguration;
	}

	return @{ @"device": device };
}

- (NSDictionary *)apiJSON {
	return @{ @"device": [ApptentiveUtilities diffDictionary:self.dictionaryRepresentation[@"device"] againstDictionary:[ApptentiveDeviceUpdater lastSavedVersion][@"device"]] };
}
@end

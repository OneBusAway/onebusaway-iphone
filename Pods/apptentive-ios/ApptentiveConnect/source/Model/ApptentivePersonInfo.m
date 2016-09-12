//
//  ApptentivePersonInfo.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePersonInfo.h"

#import "Apptentive_Private.h"
#import "ApptentiveUtilities.h"
#import "NSDictionary+Apptentive.h"
#import "ApptentivePersonUpdater.h"

NSString *const ATCurrentPersonPreferenceKey = @"ATCurrentPersonPreferenceKey";

#define kATPersonCodingVersion 1


@implementation ApptentivePersonInfo

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATPersonInfo"];
}

+ (ApptentivePersonInfo *)currentPerson {
	static ApptentivePersonInfo *_currentPerson;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSData *personData = [[NSUserDefaults standardUserDefaults] dataForKey:ATCurrentPersonPreferenceKey];
		
		if (personData) {
			@try {
				_currentPerson = [NSKeyedUnarchiver unarchiveObjectWithData:personData];
			} @catch (NSException *exception) {
				ApptentiveLogError(@"Unable to unarchive person: %@", personData);
			}
		} else {
			_currentPerson = [[ApptentivePersonInfo alloc] init];
		}
	});

	return _currentPerson;
}

+ (ApptentivePersonInfo *)newPersonFromJSON:(NSDictionary *)json {
	if (json == nil) {
		return nil;
	} else {
		return [[ApptentivePersonInfo alloc] initWithJSONDictionary:json];
	}
}

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_apptentiveID = (NSString *)[coder decodeObjectForKey:@"apptentiveID"];
		_name = (NSString *)[coder decodeObjectForKey:@"name"];
		_emailAddress = (NSString *)[coder decodeObjectForKey:@"emailAddress"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPersonCodingVersion forKey:@"version"];

	[coder encodeObject:self.apptentiveID forKey:@"apptentiveID"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.emailAddress forKey:@"emailAddress"];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)json {
	self = [super init];

	if (self) {
		_apptentiveID = [json at_safeObjectForKey:@"id"];
		_name = [json at_safeObjectForKey:@"name"];
		_emailAddress = [json at_safeObjectForKey:@"email"];
	}

	return self;
}

- (void)setName:(NSString *)name {
	_name = name;
	[self save];
}

- (void)setEmailAddress:(NSString *)emailAddress {
	_emailAddress = emailAddress;
	[self save];
}

#pragma mark - Persistence

- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *person = [NSMutableDictionary dictionary];

	if (self.name) {
		[person setObject:self.name forKey:@"name"];
	}

	if (self.emailAddress && [self.emailAddress length] > 0 && [ApptentiveUtilities emailAddressIsValid:self.emailAddress]) {
		[person setObject:self.emailAddress forKey:@"email"];
	} else if ([[self.emailAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
		// Delete a previously entered email
		[person setObject:[NSNull null] forKey:@"email"];
	}

	NSDictionary *customPersonData = [[Apptentive sharedConnection] customPersonData] ?: @{};
	[person setObject:customPersonData forKey:@"custom_data"];

	return [NSDictionary dictionaryWithObject:person forKey:@"person"];
}

- (NSDictionary *)apiJSON {
	return [ApptentiveUtilities diffDictionary:self.dictionaryRepresentation againstDictionary:[ApptentivePersonUpdater lastSavedVersion]];
}

#pragma mark - Private

- (void)save {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *personData = [NSKeyedArchiver archivedDataWithRootObject:self];

	[defaults setObject:personData forKey:ATCurrentPersonPreferenceKey];
	[defaults synchronize];
}

@end

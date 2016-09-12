//
//  ApptentiveEvent.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEvent.h"
#import "ApptentiveRecordRequestTask.h"
#import "ApptentiveData.h"
#import "ApptentiveWebClient+Metrics.h"
#import "Apptentive_Private.h"


@interface ApptentiveEvent ()
- (NSDictionary *)dictionaryForCurrentData;
- (NSData *)dataForDictionary:(NSDictionary *)dictionary;
@end


@implementation ApptentiveEvent

@dynamic pendingEventID;
@dynamic dictionaryData;
@dynamic label;

+ (instancetype)newInstanceWithJSON:(NSDictionary *)json {
	NSAssert(NO, @"Abstract method called.");
	return nil;
}

+ (instancetype)newInstanceWithLabel:(NSString *)label {
	ApptentiveEvent *result = (ApptentiveEvent *)[ApptentiveData newEntityNamed:@"ATEvent"];
	result.label = label;
	[result setup];
	return result;
}

+ (instancetype)findEventWithPendingID:(NSString *)pendingEventID {
	ApptentiveEvent *result = nil;

	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingEventID == %@)", pendingEventID];
		result = [ApptentiveData findEntityNamed:@"ATEvent" withPredicate:fetchPredicate].firstObject;
	}

	return result;
}

- (void)updateWithJSON:(NSDictionary *)json {
	[super updateWithJSON:json];
}

- (NSDictionary *)apiJSON {
	NSDictionary *parentJSON = [super apiJSON];
	NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

	if (parentJSON) {
		[result addEntriesFromDictionary:parentJSON];
	}
	if (self.label != nil) {
		result[@"label"] = self.label;
	}
	if (self.dictionaryData) {
		NSDictionary *dictionary = [self dictionaryForCurrentData];
		[result addEntriesFromDictionary:dictionary];
	}

	if (self.pendingEventID != nil) {
		result[@"nonce"] = self.pendingEventID;
	}

	// Monitor that the Event payload has not been dropped on retry
	if (!result) {
		ApptentiveLogError(@"Event json should not be nil.");
	}
	if (result.count == 0) {
		ApptentiveLogError(@"Event json should return a result.");
	}
	if (!result[@"label"]) {
		ApptentiveLogError(@"Event json should include a `label`.");
		return nil;
	}
	if (!result[@"nonce"]) {
		ApptentiveLogError(@"Event json should include a `nonce`.");
		return nil;
	}

	NSDictionary *apiJSON = @{ @"event": result };

	return apiJSON;
}

- (void)setup {
	if ([self isClientCreationTimeEmpty]) {
		[self updateClientCreationTime];
	}
	if (self.pendingEventID == nil) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);

		self.pendingEventID = [NSString stringWithFormat:@"event:%@", (__bridge NSString *)uuidStringRef];

		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
	}
}

- (void)addEntriesFromDictionary:(NSDictionary *)incomingDictionary {
	NSDictionary *dictionary = [self dictionaryForCurrentData];
	NSMutableDictionary *mutableDictionary = nil;
	if (dictionary == nil) {
		mutableDictionary = [NSMutableDictionary dictionary];
	} else {
		mutableDictionary = [dictionary mutableCopy];
	}
	if (incomingDictionary != nil) {
		[mutableDictionary addEntriesFromDictionary:incomingDictionary];
	}
	[self setDictionaryData:[self dataForDictionary:mutableDictionary]];
}

#pragma mark Private
- (NSDictionary *)dictionaryForCurrentData {
	if (self.dictionaryData == nil) {
		return @{};
	} else {
		NSDictionary *result = nil;
		@try {
			result = [NSKeyedUnarchiver unarchiveObjectWithData:self.dictionaryData];
		} @catch (NSException *exception) {
			ApptentiveLogError(@"Unable to unarchive event: %@", exception);
		}
		return result;
	}
}

- (NSData *)dataForDictionary:(NSDictionary *)dictionary {
	if (dictionary == nil) {
		return nil;
	} else {
		return [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	}
}

#pragma mark ATRequestTaskprovider
- (NSURL *)managedObjectURIRepresentationForTask:(ApptentiveRecordRequestTask *)task {
	return [[self objectID] URIRepresentation];
}

- (void)cleanupAfterTask:(ApptentiveRecordRequestTask *)task {
	[ApptentiveData deleteManagedObject:self];
}

- (ApptentiveAPIRequest *)requestForTask:(ApptentiveRecordRequestTask *)task {
	return [[Apptentive sharedConnection].webClient requestForSendingEvent:self];
}

- (ATRecordRequestTaskResult)taskResultForTask:(ApptentiveRecordRequestTask *)task withRequest:(ApptentiveAPIRequest *)request withResult:(id)result {
	return ATRecordRequestTaskFinishedResult;
}
@end

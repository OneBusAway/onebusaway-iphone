//
//  ApptentiveRecord.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecord.h"

#import "NSDictionary+Apptentive.h"


@implementation ApptentiveRecord

@dynamic apptentiveID;
@dynamic creationTime;
@dynamic clientCreationTime;
@dynamic clientCreationTimezone;
@dynamic clientCreationUTCOffset;

+ (instancetype)newInstanceWithJSON:(NSDictionary *)json {
	NSAssert(NO, @"Abstract method called.");
	return nil;
}

- (void)updateWithJSON:(NSDictionary *)json {
	NSString *tmpID = [json at_safeObjectForKey:@"id"];
	if (tmpID != nil) {
		self.apptentiveID = tmpID;
	}

	NSObject *createdAt = [json at_safeObjectForKey:@"created_at"];
	if ([createdAt isKindOfClass:[NSNumber class]]) {
		self.creationTime = (NSNumber *)createdAt;
	} else if ([createdAt isKindOfClass:[NSDate class]]) {
		NSDate *creationDate = (NSDate *)createdAt;
		NSTimeInterval t = [creationDate timeIntervalSince1970];
		NSNumber *creationTimestamp = [NSNumber numberWithFloat:t];
		self.creationTime = creationTimestamp;
	}
	if ([self isClientCreationTimeEmpty] && self.creationTime != nil) {
		self.clientCreationTime = self.creationTime;
	}
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if (self.clientCreationTime != nil) {
		result[@"client_created_at"] = self.clientCreationTime;
	}
	if (self.clientCreationTimezone != nil) {
		result[@"client_created_at_timezone"] = self.clientCreationTimezone;
	}
	if (self.clientCreationUTCOffset != nil) {
		result[@"client_created_at_utc_offset"] = self.clientCreationUTCOffset;
	}
	return result;
}

- (void)setup {
	if ([self isClientCreationTimeEmpty]) {
		[self updateClientCreationTime];
	}
	if ([self isCreationTimeEmpty]) {
		self.creationTime = self.clientCreationTime;
	}
}

- (void)updateClientCreationTime {
	NSDate *d = [NSDate date];
	NSNumber *newCreationTime = @([d timeIntervalSince1970]);

	if ([self isCreationTimeEmpty]) {
		self.creationTime = @([[NSDate distantFuture] timeIntervalSince1970]);
	}

	self.clientCreationTime = newCreationTime;
	self.clientCreationUTCOffset = @([[NSTimeZone systemTimeZone] secondsFromGMTForDate:d]);
}

- (BOOL)isClientCreationTimeEmpty {
	if (self.clientCreationTime == nil || [self.clientCreationTime doubleValue] == 0) {
		return YES;
	}
	return NO;
}

- (BOOL)isCreationTimeEmpty {
	if (self.creationTime == nil || [self.creationTime doubleValue] == 0) {
		return YES;
	}
	return NO;
}
@end

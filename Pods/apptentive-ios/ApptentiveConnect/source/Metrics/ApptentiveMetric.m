//
//  ApptentiveMetric.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveMetric.h"
#import "Apptentive_Private.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveWebClient.h"
#import "ApptentiveWebClient+Metrics.h"

#define kATMetricStorageVersion 1


@implementation ApptentiveMetric {
	NSMutableDictionary *_info;
}

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATMetric"];
}

- (id)init {
	if ((self = [super init])) {
		_info = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATMetricStorageVersion) {
			self.name = [coder decodeObjectForKey:@"name"];
			NSDictionary *d = [coder decodeObjectForKey:@"info"];
			if (_info) {
				_info = nil;
			}
			if (d != nil) {
				_info = [d mutableCopy];
			} else {
				_info = [[NSMutableDictionary alloc] init];
			}
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeInt:kATMetricStorageVersion forKey:@"version"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.info forKey:@"info"];
}


- (void)setValue:(id)value forKey:(NSString *)key {
	[_info setValue:value forKey:key];
}

- (void)addEntriesFromDictionary:(NSDictionary *)dictionary {
	if (dictionary != nil) {
		[_info addEntriesFromDictionary:dictionary];
	}
}

- (NSDictionary *)apiDictionary {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:[super apiDictionary]];

	if (self.name) [d setObject:self.name forKey:@"record[metric][event]"];

	if (self.info) {
		for (NSString *key in self.info) {
			NSString *recordKey = [NSString stringWithFormat:@"record[metric][data][%@]", key];
			NSObject *value = [self.info objectForKey:key];
			if ([value isKindOfClass:[NSDate class]]) {
				value = [ApptentiveUtilities stringRepresentationOfDate:(NSDate *)value];
			}
			[d setObject:value forKey:recordKey];
		}
	}
	return d;
}

- (ApptentiveAPIRequest *)requestForSendingRecord {
	return [[Apptentive sharedConnection].webClient requestForSendingMetric:self];
}
@end

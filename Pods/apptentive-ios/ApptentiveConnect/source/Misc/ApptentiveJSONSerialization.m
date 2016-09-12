//
//  ApptentiveJSONSerialization.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/22/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveJSONSerialization.h"


@implementation ApptentiveJSONSerialization
+ (NSData *)dataWithJSONObject:(id)obj options:(ATJSONWritingOptions)opt error:(NSError **)error {
	if ([NSJSONSerialization isValidJSONObject:obj]) {
		NSData *jsonData = nil;
		@try {
			jsonData = [NSJSONSerialization dataWithJSONObject:obj options:opterr error:error];
		} @catch (NSException *exception) {
			ApptentiveLogError(@"Unable to create JSON data from object: %@ Exception: %@", obj, exception);
		}
		return jsonData;
	} else {
		ApptentiveLogError(@"Attempting to create JSON data from an invalid JSON object.");
		return nil;
	}
}

+ (NSString *)stringWithJSONObject:(id)obj options:(ATJSONWritingOptions)opt error:(NSError **)error {
	NSData *d = [ApptentiveJSONSerialization dataWithJSONObject:obj options:opt error:error];
	if (!d) {
		return nil;
	}
	NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
	return s;
}

+ (id)JSONObjectWithData:(NSData *)data error:(NSError **)error {
	return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}

+ (id)JSONObjectWithString:(NSString *)string error:(NSError **)error {
	NSData *d = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSObject *result = [ApptentiveJSONSerialization JSONObjectWithData:d error:error];
	return result;
}
@end

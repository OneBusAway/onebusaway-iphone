//
//  ApptentiveEngagementManifestParser.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEngagementManifestParser.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionInvocation.h"


@implementation ApptentiveEngagementManifestParser {
	NSError *parserError;
}

- (NSDictionary *)targetsAndInteractionsForEngagementManifest:(NSData *)jsonManifest {
	NSMutableDictionary *targets = [NSMutableDictionary dictionary];
	NSMutableDictionary *interactions = [NSMutableDictionary dictionary];

	BOOL success = NO;

	@autoreleasepool {
		@try {
			NSError *error = nil;

			id decodedObject = [ApptentiveJSONSerialization JSONObjectWithData:jsonManifest error:&error];
			if (decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]) {
				NSDictionary *jsonDictionary = (NSDictionary *)decodedObject;

				// Targets
				NSDictionary *targetsDictionary = jsonDictionary[@"targets"];
				for (NSString *event in [targetsDictionary allKeys]) {
					NSArray *invocationsJSONArray = targetsDictionary[event];
					NSArray *invocationsArray = [ApptentiveInteractionInvocation invocationsWithJSONArray:invocationsJSONArray];
					[targets setObject:invocationsArray forKey:event];
				}

				// Interactions
				NSArray *interactionsArray = jsonDictionary[@"interactions"];
				for (NSDictionary *interactionDictionary in interactionsArray) {
					ApptentiveInteraction *interactionObject = [ApptentiveInteraction interactionWithJSONDictionary:interactionDictionary];
					[interactions setObject:interactionObject forKey:interactionObject.identifier];
				}

				success = YES;
			} else {
				parserError = nil;
				parserError = error;
				success = NO;
			}
		}
		@catch (NSException *exception) {
			ApptentiveLogError(@"Exception parsing engagement manifest: %@", exception);
			success = NO;
		}
	}

	NSDictionary *targetsAndInteractions = nil;
	if (success) {
		targetsAndInteractions = @{ @"targets": targets,
			@"interactions": interactions,
			@"raw": jsonManifest };
	}

	return targetsAndInteractions;
}

- (NSError *)parserError {
	return parserError;
}
@end

/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBALogger.h"

@interface OBALogger (Internal)

+ (void) logError:(NSError*)error prefix:(NSString*)prefix;

@end

@implementation OBALogger

+ (void) logWithLevel:(OBALoggerLevel)level pointer:(id)pointer file:(NSString*)file line:(NSInteger)line message:(NSString*)message {
	NSLog(@"# %@ - %p %@:%d",[self logLevelAsString:level],pointer,file,line);
	NSLog(@"%@",message);
}

+ (void) logWithLevel:(OBALoggerLevel)level pointer:(id)pointer file:(NSString*)file line:(NSInteger)line message:(NSString*)message error:(NSError*)error {
	[self logWithLevel:level pointer:pointer file:file line:line message:message];
	[self logError:error prefix:@""];
}

+ (NSString*) logLevelAsString:(OBALoggerLevel)level {
	switch(level) {
		case OBALoggerLevelDebug:
			return @"DEBUG";
		case OBALoggerLevelInfo:
			return @"INFO";
		case OBALoggerLevelWarning:
			return @"WARNING";
		case OBALoggerLevelSevere:
			return @"SEVERE";
		default:
			return @"UNKNOWN";
	}
}
@end

@implementation OBALogger (Internal)

+ (void) logError:(NSError*)error prefix:(NSString*)prefix {
	
	if( ! error )
		return;
	
	NSLog(@"%@%@: %@",prefix,[error localizedDescription],[error localizedFailureReason]);

	NSDictionary * userInfo = [error userInfo];

	switch( [error code] ) {
		case NSValidationMultipleErrorsError: {
			NSArray * errors = [userInfo objectForKey:@"NSDetailedErrors"];
			for( NSError * subError in errors )
				[self logError:subError prefix:[NSString stringWithFormat:@"%@  ",prefix]];
			break;
		}			
		case NSValidationMissingMandatoryPropertyError: {
			NSString * validationErrorKey = [userInfo objectForKey:@"NSValidationErrorKey"];
			id validationErrorObject = [userInfo objectForKey:@"NSValidationErrorObject"];
			NSLog(@"%@  validation error key: %@",prefix,validationErrorKey);
			NSLog(@"%@  validation error object: %@",prefix,[validationErrorObject description]);
			break;
		}
		default: {
			NSLog(@"%@  userInfo:",[userInfo description]);
		}
	}
}

@end


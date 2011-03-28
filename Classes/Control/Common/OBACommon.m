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

#import "OBACommon.h"

NSString * const OBAErrorDomain = @"org.onebusaway.iphone";

const NSInteger kOBAErrorDuplicateEntity = 1000;
const NSInteger kOBAErrorMissingFieldInData = 1001;

NSString * const OBAApplicationDidCompleteNetworkRequestNotification = @"OBAApplicationDidCompleteNetworkRequestNotification";


@implementation NSObject (OBAConvenienceMethods)

+ (id) releaseOld:(id<NSObject>)oldValue retainNew:(id<NSObject>)newValue {
	if( oldValue == newValue )
		return newValue;
	[oldValue release];
	return [newValue retain];
}

@end

@implementation NSString (OBAConvenienceMethods)

- (NSComparisonResult) compareUsingNumberSearch:(NSString*)aString {
	return [self compare:aString options:NSNumericSearch];
}

@end

@implementation OBACommon

+ (NSString*) getTimeAsString {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];	
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:kCFDateFormatterNoStyle];	
	NSString * result = [dateFormatter stringFromDate:[NSDate date]];
	[dateFormatter release];
	return result;
}

+ (NSString*) getBestNameFirst:(NSString*)firstName second:(NSString*)secondName {
	if( firstName && [firstName length] > 0 )
		return firstName;
	return secondName;
}

+ (NSString*) getBestNameFirst:(NSString*)firstName second:(NSString*)secondName third:(NSString*)thirdName {
	if( firstName && [firstName length] > 0 )
		return firstName;
	if( secondName && [secondName length] > 0 )
		return secondName;
	return thirdName;
}
@end



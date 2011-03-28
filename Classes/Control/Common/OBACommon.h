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


extern NSString * const OBAErrorDomain;
extern const NSInteger kOBAErrorDuplicateEntity;
extern const NSInteger kOBAErrorMissingFieldInData;

/**
 * Fired whenever a network request successfully completes
 */
extern NSString * const OBAApplicationDidCompleteNetworkRequestNotification;

typedef enum {
	OBANavigationTargetTypeRoot=0,
	OBANavigationTargetTypeSearch,
	OBANavigationTargetTypeSearchResults,
	OBANavigationTargetTypeBookmarks,
	OBANavigationTargetTypeRecentStops,
	OBANavigationTargetTypeStop,
	OBANavigationTargetTypeEditBookmark,
	OBANavigationTargetTypeEditStopPreferences,
	OBANavigationTargetTypeSettings,
	OBANavigationTargetTypeContactUs,
	OBANavigationTargetTypeAgencies
} OBANavigationTargetType;


@interface NSObject (OBAConvenienceMethods)
+ (id) releaseOld:(id<NSObject>)oldValue retainNew:(id<NSObject>)newValue;
@end


@interface NSString (OBAConvenienceMethods)
- (NSComparisonResult) compareUsingNumberSearch:(NSString*)aString;
@end


@interface OBACommon : NSObject

+ (NSString*) getTimeAsString;
+ (NSString*) getBestNameFirst:(NSString*)firstName second:(NSString*)secondName;
+ (NSString*) getBestNameFirst:(NSString*)firstName second:(NSString*)secondName third:(NSString*)thirdName;

@end


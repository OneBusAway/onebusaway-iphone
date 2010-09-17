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

extern NSString * const OBAErrorDomain;
extern const NSInteger kOBAErrorDuplicateEntity;
extern const NSInteger kOBAErrorMissingFieldInData;
extern const BOOL kIncludeUWActivityInferenceCode;

typedef enum {
	OK_RESPONSE = 200,
	NO_SUCH_STOP_SERVICE_EXCEPTION = 411,
	NO_SUCH_ROUTE_SERVICE_EXCEPTION = 412,
	NO_SUCH_TRIP_SERVICE_EXCEPTION = 413
} OBAErrorCode;


@interface OBAErrorCodes : NSObject {

}

+ (NSError*) getErrorFromResponseCode:(int)responseCode;

@end

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
	OBANavigationTargetTypeActivityLogging,
	OBANavigationTargetTypeActivityAnnotation,
	OBANavigationTargetTypeActivityUpload,
	OBANavigationTargetTypeActivityLock
} OBANavigationTargetType;


@interface NSObject (OBAConvenienceMethods)
+ (id) releaseOld:(id<NSObject>)oldValue retainNew:(id<NSObject>)newValue;
@end


@interface NSString (OBAConvenienceMethods)
- (NSComparisonResult) compareUsingNumberSearch:(NSString*)aString;
@end


@interface OBACommon : NSObject

+ (NSString*) getTimeAsString;

@end


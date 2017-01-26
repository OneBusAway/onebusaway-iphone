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

#import <OBAKit/OBACommon.h>
#import <OBAKit/OBADateHelpers.h>

static BOOL obaCommonRunningInsideTests = NO;

NSString * const OBAErrorDomain = @"org.onebusaway.iphone2";
NSString * const kApplicationShortcutMap = @"org.onebusaway.iphone.shortcut.map";
NSString * const kApplicationShortcutRecents = @"org.onebusaway.iphone.shortcut.recents";
NSString * const kApplicationShortcutBookmarks = @"org.onebusaway.iphone.shortcut.bookmarks";

NSString * const OBAOptInToTrackingDefaultsKey = @"OBAOptInToTrackingDefaultsKey";
NSString * const OBAOptInToCrashReportingDefaultsKey = @"OBAOptInToCrashReportingDefaultsKey";
NSString * const OBAAllowReviewPromptsDefaultsKey = @"OBAAllowReviewPromptsDefaultsKey";
NSString * const OBAMapSelectedTypeDefaultsKey = @"OBAMapSelectedTypeDefaultsKey";

NSString * const OBADeepLinkServerAddress = @"https://www.onebusaway.co";

const NSInteger kOBAErrorDuplicateEntity = 1000;
const NSInteger kOBAErrorMissingFieldInData = 1001;

NSString * OBAStringFromBool(BOOL yn) {
    return yn ? @"YES" : @"NO";
}

@implementation OBACommon

+ (void)setRunningInsideTests:(BOOL)runningInsideTests {
    obaCommonRunningInsideTests = runningInsideTests;
}

+ (BOOL)isRunningInsideTests {
    return obaCommonRunningInsideTests;
}

@end



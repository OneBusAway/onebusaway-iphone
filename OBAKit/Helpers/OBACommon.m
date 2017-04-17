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
#import <OBAKit/OBAMacros.h>

static BOOL obaCommonRunningInsideTests = NO;

NSString * const OBAErrorDomain = @"org.onebusaway.iphone2";
NSString * const kApplicationShortcutMap = @"org.onebusaway.iphone.shortcut.map";
NSString * const kApplicationShortcutRecents = @"org.onebusaway.iphone.shortcut.recents";
NSString * const kApplicationShortcutBookmarks = @"org.onebusaway.iphone.shortcut.bookmarks";

NSString * const OBAOptInToTrackingDefaultsKey = @"OBAOptInToTrackingDefaultsKey";
NSString * const OBAOptInToCrashReportingDefaultsKey = @"OBAOptInToCrashReportingDefaultsKey";
NSString * const OBAAllowReviewPromptsDefaultsKey = @"OBAAllowReviewPromptsDefaultsKey";
NSString * const OBAMapSelectedTypeDefaultsKey = @"OBAMapSelectedTypeDefaultsKey";
NSString * const OBADebugModeUserDefaultsKey = @"OBADebugModeUserDefaultsKey";

NSString * const OBADeepLinkServerAddress = @"https://www.onebusaway.co";

NSString * NSStringFromOBASearchType(OBASearchType searchType) {
    switch (searchType) {
        case OBASearchTypePending: {
            return OBALocalized(@"search_type.pending", @"OBASearchTypePending. Rendered as 'Pending' in English.");
        }
        case OBASearchTypeRegion: {
            return OBALocalized(@"search_type.region", @"OBASearchTypeRegion. Rendered as 'Region' in English.");
        }
        case OBASearchTypeRoute: {
            return OBALocalized(@"search_type.route", @"OBASearchTypeRoute. Rendered as 'Route' in English.");
        }
        case OBASearchTypeStops: {
            return OBALocalized(@"search_type.stops", @"OBASearchTypeStops. Rendered as 'Stops' in English.");
        }
        case OBASearchTypeAddress: {
            return OBALocalized(@"search_type.address", @"OBASearchTypeAddress. Rendered as 'Address' in English.");
        }
        case OBASearchTypePlacemark: {
            return OBALocalized(@"search_type.placemark", @"OBASearchTypePlacemark. Rendered as 'Placemark' in English.");
        }
        case OBASearchTypeStopId: {
            return OBALocalized(@"search_type.stop_id", @"OBASearchTypeStopId. Rendered as 'Stop ID' in English.");
        }
        default: {
            return nil;
        }
    }
}

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

+ (BOOL)debugMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:OBADebugModeUserDefaultsKey];
}

+ (void)setDebugMode:(BOOL)debugMode {
    [[NSUserDefaults standardUserDefaults] setBool:debugMode forKey:OBADebugModeUserDefaultsKey];
}

@end



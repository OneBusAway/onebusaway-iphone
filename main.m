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

#import <UIKit/UIKit.h>

#if OBA_RUNNING_TESTS
#import <OBAKit/OBAKit.h>
#import <CoreLocation/CoreLocation.h>

@interface CLLocationManager (TestInterface)
+ (void)setAuthorizationStatus:(BOOL)authStatus forBundleIdentifier:(NSString*)bundleIdentifier;
@end
#endif

@interface OBATestAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation OBATestAppDelegate
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {

#if OBA_RUNNING_TESTS
        [CLLocationManager setAuthorizationStatus:YES forBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
        [OBACommon setRunningInsideTests:YES];
#endif

        int retVal = UIApplicationMain(argc, argv, nil, @"OBAApplicationDelegate");
        return retVal;
    }
}


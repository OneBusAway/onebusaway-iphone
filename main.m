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
#import <OBAKit/OBAKit.h>

@interface OBATestAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation OBATestAppDelegate
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSDictionary *processInfoEnv = [NSProcessInfo processInfo].environment;

        BOOL executingTests = [[processInfoEnv[@"XCInjectBundle"] pathExtension] isEqual:@"xctest"];
        if (!executingTests) {
            executingTests = !!processInfoEnv[@"XCInjectBundleInto"];
        }

        NSString *appDelegateClass = executingTests ? @"OBATestAppDelegate" : @"OBAApplicationDelegate";

        [OBACommon setRunningInsideTests:executingTests];

        int retVal = UIApplicationMain(argc, argv, nil, appDelegateClass);
        return retVal;
    }
}


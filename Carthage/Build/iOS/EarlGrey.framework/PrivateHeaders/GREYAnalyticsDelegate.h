//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

@protocol GREYAnalyticsDelegate<NSObject>

@required
/**
 *  Sent to the delegate to handle Analytics Event hit. See this for more info:
 *  https://developers.google.com/analytics/devguides/collection/protocol/v1/.
 *
 *  @note In case of failure to track the method must fail silently to prevent test interruption.
 *
 *  @param trackingID  The tracking ID under which to track this event.
 *  @param category    The category value for the event hit.
 *  @param subCategory The subcategory(also called label) for the event hit.
 *  @param valueOrNil  An optional value for the event hit.
 */
- (void)trackEventWithTrackingID:(NSString *)trackingID
                        category:(NSString *)category
                     subCategory:(NSString *)subCategory
                           value:(NSNumber *)valueOrNil;

@end

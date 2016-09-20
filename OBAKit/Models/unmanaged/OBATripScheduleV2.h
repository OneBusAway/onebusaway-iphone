/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBATripV2.h>
#import <OBAKit/OBAFrequencyV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATripScheduleV2 : OBAHasReferencesV2

@property (nonatomic,strong) NSString * timeZone;
@property (nonatomic,strong) NSArray * stopTimes;
@property (nonatomic,strong) OBAFrequencyV2 * frequency;
@property (nonatomic,strong) NSString * previousTripId;
@property (nonatomic,strong) NSString * nextTripId;

- (nullable OBATripV2*)previousTrip;
- (nullable OBATripV2*)nextTrip;
@end

NS_ASSUME_NONNULL_END

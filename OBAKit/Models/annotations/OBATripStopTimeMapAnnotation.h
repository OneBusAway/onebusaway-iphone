/*
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

#import <OBAKit/OBATripDetailsV2.h>
#import <OBAKit/OBATripStopTimeV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATripStopTimeMapAnnotation : NSObject <MKAnnotation>
@property(nonatomic,strong) OBATripDetailsV2 *tripDetails;
@property(nonatomic,strong) OBATripStopTimeV2 * stopTime;
@property(nonatomic,copy,readonly) NSString *stopID;

- (instancetype)initWithTripDetails:(OBATripDetailsV2*)tripDetails stopTime:(OBATripStopTimeV2*)stopTime;

@end

NS_ASSUME_NONNULL_END

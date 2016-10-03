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

#import <CoreLocation/CoreLocation.h>
#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBATripInstanceRef.h>
#import <OBAKit/OBATripV2.h>
#import <OBAKit/OBAFrequencyV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATripStatusV2 : OBAHasReferencesV2

@property (nonatomic,strong) NSString * activeTripId;
@property (weak, nonatomic,readonly) OBATripV2 * activeTrip;

@property (nonatomic) long long serviceDate;
@property (nonatomic,strong) OBAFrequencyV2 * frequency;

@property (nonatomic,strong) CLLocation * location;
@property (nonatomic) BOOL predicted;
@property (nonatomic) NSInteger scheduleDeviation;
@property(nonatomic,copy,readonly) NSString *formattedScheduleDeviation;
@property (nonatomic,strong) NSString * vehicleId;

@property (nonatomic) long long lastUpdateTime;
@property (nonatomic,strong) CLLocation * lastKnownLocation;

@property (weak, nonatomic,readonly) OBATripInstanceRef * tripInstance;

@end

NS_ASSUME_NONNULL_END

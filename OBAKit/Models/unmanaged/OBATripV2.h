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
#import <OBAKit/OBARouteV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATripV2 : OBAHasReferencesV2

@property (nonatomic, strong) NSString * tripId;
@property (nonatomic, strong) NSString * routeId;
@property (nonatomic, strong) NSString * routeShortName;
@property (nonatomic, strong) NSString * tripShortName;
@property (nonatomic, strong) NSString * tripHeadsign;
@property (nonatomic, strong) NSString * serviceId;
@property (nonatomic, strong) NSString * shapeId;
@property (nonatomic, strong) NSString * directionId;
@property (nonatomic, strong) NSString * blockId;

@property(weak, nonatomic, readonly) OBARouteV2 * route;

@property(nonatomic,copy,readonly) NSString *asLabel;

@end

NS_ASSUME_NONNULL_END

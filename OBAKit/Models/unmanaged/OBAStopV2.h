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

#import <MapKit/MapKit.h>
#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBARouteType.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAStopV2 : OBAHasReferencesV2 <MKAnnotation,NSCoding,NSCopying>

@property(nonatomic,copy,readonly) NSString *nameWithDirection;

@property (nonatomic, strong) NSString * stopId;
@property (nonatomic, strong) NSString * name;

/**
 The stop number. A unique identifier for the stop
 within its transit system. In Puget Sound, e.g.,
 these stop numbers are actually written on the bus stops.
 */
@property (nonatomic, strong) NSString * code;
@property (nonatomic, strong) NSString * direction;
@property (nonatomic, strong) NSArray<NSString*> *routeIds;

@property(nonatomic,strong,readonly) NSArray<OBARouteV2*> *routes;

@property(nonatomic,assign) double lat;
@property(nonatomic,assign) double lon;
@property(nonatomic,readonly) CLLocationCoordinate2D coordinate;

- (NSComparisonResult)compareUsingName:(OBAStopV2*)aStop;

- (NSString*)routeNamesAsString;

- (OBARouteType)firstAvailableRouteTypeForStop;

@end

NS_ASSUME_NONNULL_END

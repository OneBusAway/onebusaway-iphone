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

@import MapKit;
#import <OBAKit/OBARegionBoundsV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBARegionV2 : NSObject<NSCoding>
@property(nonatomic,copy,nullable) NSString * siriBaseUrl;
@property(nonatomic,copy,nullable) NSString * obaVersionInfo;
@property(nonatomic,copy,nullable) NSString * language;
@property(nonatomic,strong) NSArray * bounds;
@property(nonatomic,copy,nullable) NSString * contactEmail;
@property(nonatomic,copy,nullable) NSString * twitterUrl;
@property(nonatomic,copy) NSString * obaBaseUrl;
@property(nonatomic,copy,nullable) NSString * facebookUrl;
@property(nonatomic,copy) NSString * regionName;
@property(nonatomic,assign) BOOL supportsSiriRealtimeApis;
@property(nonatomic,assign) BOOL supportsObaRealtimeApis;
@property(nonatomic,assign) BOOL supportsObaDiscoveryApis;
@property(nonatomic,assign) BOOL active;
@property(nonatomic,assign) BOOL experimental;
@property(nonatomic,assign) NSInteger identifier;

/**
 Signifies that this was created in the RegionBuilderViewController
 */
@property(nonatomic,assign) BOOL custom;

- (void)addBound:(OBARegionBoundsV2*)bound;
- (CLLocationDistance)distanceFromLocation:(CLLocation*)location;

@property(nonatomic,assign,readonly) MKMapRect serviceRect;

/**
 The location coordinate in the center of the `serviceRect`.
 */
@property(nonatomic,assign,readonly) CLLocationCoordinate2D centerCoordinate;

/**
 Tests whether this is a valid region object.
 */
- (BOOL)isValidModel;

/**
 obaBaseUrl converted into an NSURL
 */
@property(nonatomic,copy,nullable,readonly) NSURL *baseURL;

@end

NS_ASSUME_NONNULL_END

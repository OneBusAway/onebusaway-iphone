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

@import MapKit;
#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBAAgencyV2.h>
#import <OBAKit/OBARegionBoundsV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAAgencyWithCoverageV2 : OBAHasReferencesV2
@property(nonatomic,copy) NSString *agencyId;
@property(weak,nonatomic,readonly) OBAAgencyV2 *agency;
@property(nonatomic,assign) CLLocationCoordinate2D coordinate;

@property(nonatomic,assign) double lat;
@property(nonatomic,assign) double latSpan;
@property(nonatomic,assign) double lon;
@property(nonatomic,assign) double lonSpan;

@property(nonatomic,copy,nullable,readonly) OBARegionBoundsV2 *regionBounds;

- (NSComparisonResult)compareUsingAgencyName:(OBAAgencyWithCoverageV2*)obj;

@end

NS_ASSUME_NONNULL_END

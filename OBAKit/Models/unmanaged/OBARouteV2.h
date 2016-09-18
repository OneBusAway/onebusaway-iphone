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
#import <OBAKit/OBAAgencyV2.h>
#import <OBAKit/OBARouteType.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBARouteV2 : OBAHasReferencesV2<NSCopying,NSCoding>
@property(nonatomic,strong) NSString * routeId;
@property(nonatomic,strong) NSString * shortName;
@property(nonatomic,strong) NSString * longName;

/**
 An amalgamation of shortName and longName
 */
@property(nonatomic,copy,readonly) NSString *fullRouteName;
@property(nonatomic,strong) NSNumber * routeType;

@property(nonatomic,strong) NSString * agencyId;
@property(nonatomic,copy, readonly) OBAAgencyV2 *agency;
@property(nonatomic,copy, readonly) NSString * safeShortName;

- (NSComparisonResult) compareUsingName:(OBARouteV2*)aRoute;

@end

NS_ASSUME_NONNULL_END

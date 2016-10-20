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

@import Foundation;
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@interface OBAReportProblemWithStopV2 : NSObject

@property (nonatomic,strong) NSString *stopId;
@property (nonatomic,strong) NSString *code;
@property (nonatomic,strong) NSString *userComment;
@property (nonatomic,strong) CLLocation *userLocation;

@end

NS_ASSUME_NONNULL_END

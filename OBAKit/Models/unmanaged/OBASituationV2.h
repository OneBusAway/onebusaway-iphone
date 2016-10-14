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
#import <OBAKit/OBASituationConsequenceV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBASituationV2 : OBAHasReferencesV2

@property (nonatomic,strong) NSString * situationId;
@property (nonatomic) long long creationTime;

/**
 Short summary
 */
@property (nonatomic,strong) NSString * summary;

/**
 Longer description
 */
@property (nonatomic,strong) NSString * description;

/**
 Advice to the rider
 */
@property (nonatomic,strong) NSString * advice;

@property(nonatomic,copy,readonly) NSString *diversionPath;

/**
 consquences captures a list of OBASituationConsequenceV2 objects that provide details about the consequences of the service alert. Right now, we mostly use this to share reroute information.
 */
@property (nonatomic,strong) NSArray<OBASituationConsequenceV2*> *consequences;

@property (nonatomic,strong) NSString * severity;
@property (nonatomic,strong) NSString * sensitivity;

- (NSInteger)severityAsNumericValue;

@property(nonatomic,copy,readonly) NSString *formattedDetails;

@end

NS_ASSUME_NONNULL_END

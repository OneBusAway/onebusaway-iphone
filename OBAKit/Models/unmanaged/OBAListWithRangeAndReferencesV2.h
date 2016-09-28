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

#import <OBAKit/OBAHasReferencesV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAListWithRangeAndReferencesV2 : OBAHasReferencesV2 {
    BOOL _limitExceeded;
    BOOL _outOfRange;
    NSMutableArray * _values;
}

@property (nonatomic) BOOL limitExceeded;
@property (nonatomic) BOOL outOfRange;
@property (nonatomic,strong) NSArray * values;

@property (nonatomic,readonly) NSUInteger count;

- (void) addValue:(id)value;

@end

NS_ASSUME_NONNULL_END

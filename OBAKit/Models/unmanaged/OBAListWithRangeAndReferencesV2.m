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

#import <OBAKit/OBAListWithRangeAndReferencesV2.h>

@interface OBAListWithRangeAndReferencesV2 ()
@property(nonatomic,strong) NSMutableArray *mutableValues;
@end

@implementation OBAListWithRangeAndReferencesV2

- (instancetype)initWithReferences:(OBAReferencesV2*)refs {
    self = [super initWithReferences:refs];
    if (self) {
        _mutableValues = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSArray*)values {
    return [NSArray arrayWithArray:_mutableValues];
}

- (void)addValue:(id)value {
    [_mutableValues addObject:value];
}

- (NSUInteger)count {
    return _mutableValues.count;
}

@end

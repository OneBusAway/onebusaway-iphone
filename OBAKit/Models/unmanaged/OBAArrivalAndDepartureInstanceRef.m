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

#import <OBAKit/OBAArrivalAndDepartureInstanceRef.h>
#import <OBAKit/NSObject+OBADescription.h>

@implementation OBAArrivalAndDepartureInstanceRef

- (instancetype)initWithTripInstance:(OBATripInstanceRef*)tripInstance stopId:(NSString*)stopId stopSequence:(NSInteger)stopSequence {
    self = [super init];

    if (self) {
        _tripInstance = tripInstance;
        _stopId = stopId;
        _stopSequence = stopSequence;
    }
    return self;
}

- (BOOL)isEqual:(OBAArrivalAndDepartureInstanceRef*)instanceRef {

    if (self == instanceRef) {
        return YES;
    }

    if (![instanceRef isKindOfClass:self.class]) {
        return NO;
    }

    if (![self.tripInstance isEqual:instanceRef.tripInstance]) {
        return NO;
    }

    if (![self.stopId isEqual:instanceRef.stopId]) {
        return NO;
    }

    if (self.stopSequence != instanceRef.stopSequence) {
        return NO;
    }

    return YES;
}

- (NSString*)description {
    return [self oba_description:@[@"tripInstance", @"stopId", @"stopSequence"]];
}

@end

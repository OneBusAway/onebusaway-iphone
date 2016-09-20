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

#import <OBAKit/OBASearchResult.h>
#import <OBAKit/OBASphericalGeometryLibrary.h>
#import <OBAKit/OBAStopV2.h>

@implementation OBASearchResult

+ (OBASearchResult*) result {
    return [[OBASearchResult alloc] init];
}

+ (OBASearchResult*) resultFromList:(OBAListWithRangeAndReferencesV2*)list {
    OBASearchResult * result = [[OBASearchResult alloc] init];
    result.values = list.values;
    result.outOfRange = list.outOfRange;
    result.limitExceeded = list.limitExceeded;
    return result;
}

- (id) init {
    if( self = [super init] ) {
        _searchType = OBASearchTypeNone;
        _limitExceeded = NO;
        _outOfRange = NO;
        _values = [[NSArray alloc] init];
        _additionalValues = [[NSArray alloc] init];
    }
    return self;
}


- (OBASearchResult*) resultsInRegion:(MKCoordinateRegion)region {
    OBASearchResult * result = [[OBASearchResult alloc] init];
    result.searchType = self.searchType;
    result.outOfRange = self.outOfRange;
    result.limitExceeded = self.limitExceeded;
    
    NSMutableArray * values = [[NSMutableArray alloc] init];
    
    for (id object in self.values) {
        if( [object isKindOfClass:[OBAStopV2 class]] ) {
            OBAStopV2 * stop = (OBAStopV2*) object;
            if( [OBASphericalGeometryLibrary isCoordinate:stop.coordinate containedBy:region] )
                [values addObject:object];
        }
        else {
            [values addObject:object];
        }
    }
    
    result.values = values;
    
    return result;
    
}

- (NSUInteger) count {
    return [_values count];
}

@end


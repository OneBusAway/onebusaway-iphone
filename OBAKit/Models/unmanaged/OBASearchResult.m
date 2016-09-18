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


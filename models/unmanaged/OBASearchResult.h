#import "OBASearch.h"


@interface OBASearchResult : NSObject
{
    OBASearchType _searchType;
    BOOL _limitExceeded;
    BOOL _outOfRange;
    NSArray * _values;
    NSArray * _additionalValues;
}

@property (nonatomic) OBASearchType searchType;
@property (nonatomic) BOOL limitExceeded;
@property (nonatomic) BOOL outOfRange;
@property (nonatomic,strong) NSArray * values;
@property (nonatomic,strong) NSArray * additionalValues;

+ (OBASearchResult*) result;
+ (OBASearchResult*) resultFromList:(OBAListWithRangeAndReferencesV2*)list;

- (OBASearchResult*) resultsInRegion:(MKCoordinateRegion)region;
- (NSUInteger) count;

@end
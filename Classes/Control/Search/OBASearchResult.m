#import "OBASearchResult.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBAStopV2.h"


@implementation OBASearchResult

@synthesize searchType = _searchType;
@synthesize limitExceeded = _limitExceeded;
@synthesize outOfRange = _outOfRange;
@synthesize values = _values;
@synthesize additionalValues = _additionalValues;

+ (OBASearchResult*) result {
	return [[[OBASearchResult alloc] init] autorelease];
}

+ (OBASearchResult*) resultFromList:(OBAListWithRangeAndReferencesV2*)list {
	OBASearchResult * result = [[[OBASearchResult alloc] init] autorelease];
	result.values = list.values;
	result.outOfRange = list.outOfRange;
	result.limitExceeded = list.limitExceeded;
	return result;
}

- (id) init {
	if( self = [super init] ) {
		_searchType = OBASearchTypeNone;
		_limitExceeded = FALSE;
		_outOfRange = FALSE;
		_values = [[NSArray alloc] init];
		_additionalValues = [[NSArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_values release];
	[_additionalValues release];
	[super dealloc];
}

- (OBASearchResult*) resultsInRegion:(MKCoordinateRegion)region {
	OBASearchResult * result = [[[OBASearchResult alloc] init] autorelease];
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


#import "OBAHasReferencesV2.h"


@interface OBAListWithRangeAndReferencesV2 : OBAHasReferencesV2 {
	BOOL _limitExceeded;
	BOOL _outOfRange;
	NSMutableArray * _values;
}

@property (nonatomic) BOOL limitExceeded;
@property (nonatomic) BOOL outOfRange;
@property (nonatomic,retain) NSArray * values;

@property (nonatomic,readonly) NSUInteger count;

- (void) addValue:(id)value;

@end

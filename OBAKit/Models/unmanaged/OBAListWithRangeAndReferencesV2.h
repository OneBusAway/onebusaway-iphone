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

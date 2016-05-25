#import "OBAHasReferencesV2.h"
#import "OBATripV2.h"
#import "OBAFrequencyV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBATripScheduleV2 : OBAHasReferencesV2

@property (nonatomic,strong) NSString * timeZone;
@property (nonatomic,strong) NSArray * stopTimes;
@property (nonatomic,strong) OBAFrequencyV2 * frequency;
@property (nonatomic,strong) NSString * previousTripId;
@property (nonatomic,strong) NSString * nextTripId;

- (nullable OBATripV2*)previousTrip;
- (nullable OBATripV2*)nextTrip;
@end

NS_ASSUME_NONNULL_END
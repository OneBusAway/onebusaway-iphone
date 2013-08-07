#import "OBAHasReferencesV2.h"
#import "OBATripV2.h"
#import "OBAFrequencyV2.h"


@interface OBATripScheduleV2 : OBAHasReferencesV2 {

}

@property (nonatomic,strong) NSString * timeZone;
@property (nonatomic,strong) NSArray * stopTimes;
@property (nonatomic,strong) OBAFrequencyV2 * frequency;
@property (nonatomic,strong) NSString * previousTripId;
@property (nonatomic,strong) NSString * nextTripId;

@property (weak, nonatomic,readonly) OBATripV2 * previousTrip;
@property (weak, nonatomic,readonly) OBATripV2 * nextTrip;




@end

#import "OBAHasReferencesV2.h"
#import "OBATripV2.h"
#import "OBAFrequencyV2.h"


@interface OBATripScheduleV2 : OBAHasReferencesV2 {

}

@property (nonatomic,retain) NSString * timeZone;
@property (nonatomic,retain) NSArray * stopTimes;
@property (nonatomic,retain) OBAFrequencyV2 * frequency;
@property (nonatomic,retain) NSString * previousTripId;
@property (nonatomic,retain) NSString * nextTripId;

@property (nonatomic,readonly) OBATripV2 * previousTrip;
@property (nonatomic,readonly) OBATripV2 * nextTrip;




@end

#import "OBAHasReferencesV2.h"
#import "OBAStopV2.h"


@interface OBATripStopTimeV2 : OBAHasReferencesV2 {

}

@property (nonatomic) NSInteger arrivalTime;
@property (nonatomic) NSInteger departureTime;
@property (nonatomic,strong) NSString * stopId;

@property (weak, nonatomic,readonly) OBAStopV2 * stop;
@end

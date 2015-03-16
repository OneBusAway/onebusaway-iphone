#import "OBATripStatusV2.h"


@interface OBACurrentVehicleEstimateV2 : NSObject

@property (nonatomic) double probability;
@property (nonatomic,strong) OBATripStatusV2 * tripStatus;
@property (nonatomic,strong) NSString * debug;

@end

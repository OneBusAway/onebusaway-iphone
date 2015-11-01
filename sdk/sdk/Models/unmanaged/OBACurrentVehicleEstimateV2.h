#import "OBATripStatusV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBACurrentVehicleEstimateV2 : NSObject

@property (nonatomic,assign) double probability;
@property (nonatomic,strong) OBATripStatusV2 * tripStatus;
@property (nonatomic,strong) NSString * debug;

@end

NS_ASSUME_NONNULL_END
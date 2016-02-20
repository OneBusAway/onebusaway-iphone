#import "OBAHasReferencesV2.h"
#import "OBATripV2.h"
#import "OBATripStatusV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAVehicleStatusV2 : OBAHasReferencesV2

@property (nonatomic,strong) NSString * vehicleId;
@property (nonatomic) long long lastUpdateTime;

@property (nonatomic,strong) NSString * tripId;
@property (weak, nonatomic,readonly) OBATripV2 * trip;

@property (nonatomic,strong) OBATripStatusV2 * tripStatus;

@end

NS_ASSUME_NONNULL_END
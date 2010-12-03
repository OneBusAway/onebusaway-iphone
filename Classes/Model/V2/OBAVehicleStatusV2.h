#import "OBAHasReferencesV2.h"
#import "OBATripV2.h"
#import "OBATripStatusV2.h"


@interface OBAVehicleStatusV2 : OBAHasReferencesV2 {

}

@property (nonatomic,retain) NSString * vehicleId;
@property (nonatomic) long long lastUpdateTime;

@property (nonatomic,retain) NSString * tripId;
@property (nonatomic,readonly) OBATripV2 * trip;

@property (nonatomic,retain) OBATripStatusV2 * tripStatus;

@end
#import "OBAHasReferencesV2.h"
#import "OBATripInstanceRef.h"
#import "OBATripV2.h"
#import "OBAFrequencyV2.h"


@interface OBATripStatusV2 : OBAHasReferencesV2 {

}

@property (nonatomic,strong) NSString * activeTripId;
@property (weak, nonatomic,readonly) OBATripV2 * activeTrip;

@property (nonatomic) long long serviceDate;
@property (nonatomic,strong) OBAFrequencyV2 * frequency;

@property (nonatomic,strong) CLLocation * location;
@property (nonatomic) BOOL predicted;
@property (nonatomic) NSInteger scheduleDeviation;
@property (nonatomic,strong) NSString * vehicleId;

@property (nonatomic) long long lastUpdateTime;
@property (nonatomic,strong) CLLocation * lastKnownLocation;

@property (weak, nonatomic,readonly) OBATripInstanceRef * tripInstance;

@end

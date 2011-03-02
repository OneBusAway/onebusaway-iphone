#import "OBAHasReferencesV2.h"
#import "OBATripInstanceRef.h"
#import "OBATripV2.h"
#import "OBAFrequencyV2.h"


@interface OBATripStatusV2 : OBAHasReferencesV2 {

}

@property (nonatomic,retain) NSString * activeTripId;
@property (nonatomic,readonly) OBATripV2 * activeTrip;

@property (nonatomic) long long serviceDate;
@property (nonatomic,retain) OBAFrequencyV2 * frequency;

@property (nonatomic,retain) CLLocation * location;
@property (nonatomic) BOOL predicted;
@property (nonatomic) NSInteger scheduleDeviation;
@property (nonatomic,retain) NSString * vehicleId;

@property (nonatomic) long long lastUpdateTime;
@property (nonatomic,retain) CLLocation * lastKnownLocation;

@property (nonatomic,readonly) OBATripInstanceRef * tripInstance;

@end

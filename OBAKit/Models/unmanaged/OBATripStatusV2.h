#import <CoreLocation/CoreLocation.h>
#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBATripInstanceRef.h>
#import <OBAKit/OBATripV2.h>
#import <OBAKit/OBAFrequencyV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATripStatusV2 : OBAHasReferencesV2

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

NS_ASSUME_NONNULL_END

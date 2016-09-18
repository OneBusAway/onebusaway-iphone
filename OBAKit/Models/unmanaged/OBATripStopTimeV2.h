#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBAStopV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATripStopTimeV2 : OBAHasReferencesV2

@property (nonatomic) NSInteger arrivalTime;
@property (nonatomic) NSInteger departureTime;
@property (nonatomic,strong) NSString * stopId;

@property (weak, nonatomic,readonly) OBAStopV2 * stop;
@end

NS_ASSUME_NONNULL_END

#import "OBATripInstanceRef.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalAndDepartureInstanceRef : NSObject

- (id) initWithTripInstance:(OBATripInstanceRef*)tripInstance stopId:(NSString*)stopId stopSequence:(NSInteger)stopSequence;

+ (OBAArrivalAndDepartureInstanceRef*) refWithTripInstance:(OBATripInstanceRef*)tripInstance stopId:(NSString*)stopId stopSequence:(NSInteger)stopSequence;

@property (nonatomic,readonly) OBATripInstanceRef * tripInstance;
@property (nonatomic,readonly) NSString * stopId;
@property (nonatomic,readonly) NSInteger stopSequence;

- (BOOL) isEqualWithOptionalVehicleId:(OBAArrivalAndDepartureInstanceRef*)ref;

@end

NS_ASSUME_NONNULL_END
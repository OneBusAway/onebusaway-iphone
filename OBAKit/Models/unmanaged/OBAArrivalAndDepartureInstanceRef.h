#import "OBATripInstanceRef.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalAndDepartureInstanceRef : NSObject
@property(nonatomic,strong,readonly) OBATripInstanceRef * tripInstance;
@property(nonatomic,strong,readonly) NSString * stopId;
@property(nonatomic,assign,readonly) NSInteger stopSequence;

- (instancetype)initWithTripInstance:(OBATripInstanceRef*)tripInstance stopId:(NSString*)stopId stopSequence:(NSInteger)stopSequence;
@end

NS_ASSUME_NONNULL_END
@interface OBATripInstanceRef : NSObject {
	NSString * _tripId;
	long long _serviceDate;
	NSString * _vehicleId;
}

- (id) initWithTripId:(NSString*)tripId serviceDate:(long long)serviceDate vehicleId:(NSString*)vehicleId;

+ (OBATripInstanceRef*) tripInstance:(NSString*)tripId serviceDate:(long long)serviceDate vehicleId:(NSString*)vehicleId;

@property (nonatomic,readonly) NSString * tripId;
@property (nonatomic,readonly) long long serviceDate;
@property (nonatomic,readonly) NSString * vehicleId;

- (OBATripInstanceRef*) copyWithNewTripId:(NSString*)newTripId;

@end

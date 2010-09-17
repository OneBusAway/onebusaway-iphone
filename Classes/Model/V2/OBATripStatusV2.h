@interface OBATripStatusV2 : NSObject {

}

@property (nonatomic) long long serviceDate;
@property (nonatomic,retain) CLLocation * location;
@property (nonatomic) BOOL predicted;
@property (nonatomic) NSInteger scheduleDeviation;
@property (nonatomic,retain) NSString * vehicleId;

@end

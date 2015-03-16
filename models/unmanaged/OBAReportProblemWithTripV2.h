#import "OBATripInstanceRef.h"


@interface OBAReportProblemWithTripV2 : NSObject 

@property (nonatomic,strong) OBATripInstanceRef *tripInstance;
@property (nonatomic,strong) NSString *stopId;
@property (nonatomic,strong) NSString *code;
@property (nonatomic,strong) NSString *userComment;
@property (nonatomic) BOOL userOnVehicle;
@property (nonatomic,strong) NSString *userVehicleNumber;
@property (nonatomic,strong) CLLocation *userLocation;

@end
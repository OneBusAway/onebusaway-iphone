@interface OBAReportProblemWithStopV2 : NSObject

@property (nonatomic,strong) NSString *stopId;
@property (nonatomic,strong) NSString *code;
@property (nonatomic,strong) NSString *userComment;
@property (nonatomic,strong) CLLocation *userLocation;

@end
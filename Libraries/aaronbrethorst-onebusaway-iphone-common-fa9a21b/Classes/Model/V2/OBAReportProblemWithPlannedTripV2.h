@interface OBAReportProblemWithPlannedTripV2 : NSObject {
    
}

@property (nonatomic,strong) CLLocation * fromLocation;
@property (nonatomic,strong) CLLocation * toLocation;
@property (nonatomic,strong) NSDate * time;
@property (nonatomic) BOOL arriveBy;
@property (nonatomic,strong) NSString * data;
@property (nonatomic,strong) NSString * userComment;
@property (nonatomic,strong) CLLocation * userLocation;

@end

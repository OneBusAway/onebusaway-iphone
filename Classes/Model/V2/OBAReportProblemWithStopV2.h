@interface OBAReportProblemWithStopV2 : NSObject {

}

@property (nonatomic,retain) NSString * stopId;
@property (nonatomic,retain) NSString * data;
@property (nonatomic,retain) NSString * userComment;
@property (nonatomic,retain) CLLocation * userLocation;

@end
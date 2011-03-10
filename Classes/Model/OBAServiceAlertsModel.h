@interface OBAServiceAlertsModel : NSObject {

}

@property (nonatomic) NSUInteger unreadCount;
@property (nonatomic) NSUInteger totalCount;

@property (nonatomic,retain) NSString * unreadMaxSeverity;
@property (nonatomic,retain) NSString * maxSeverity;


@end

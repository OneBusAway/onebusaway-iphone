@import Foundation;
@interface OBAServiceAlertsModel : NSObject

@property (nonatomic) NSUInteger unreadCount;
@property (nonatomic) NSUInteger totalCount;

@property (nonatomic,strong) NSString * unreadMaxSeverity;
@property (nonatomic,strong) NSString * maxSeverity;


@end

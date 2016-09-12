#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAServiceAlertsModel : NSObject

@property (nonatomic) NSUInteger unreadCount;
@property (nonatomic) NSUInteger totalCount;

@property (nonatomic,strong) NSString * unreadMaxSeverity;
@property (nonatomic,strong) NSString * maxSeverity;

@end

NS_ASSUME_NONNULL_END

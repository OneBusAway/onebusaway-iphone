#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAStopAccessEventV2 : NSObject <NSCoding>

@property (nonatomic,strong) NSString * title;
@property (nonatomic,strong) NSString * subtitle;
@property (nonatomic,strong) NSArray * stopIds;

@end

NS_ASSUME_NONNULL_END

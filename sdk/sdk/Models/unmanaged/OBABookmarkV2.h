@class OBABookmarkGroup;
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface OBABookmarkV2 : NSObject<NSCoding>
@property(nonatomic,strong) NSString *name;
@property(nonatomic,strong) NSArray *stopIds;
@property(nonatomic,strong,nullable) OBABookmarkGroup *group;
@end

NS_ASSUME_NONNULL_END

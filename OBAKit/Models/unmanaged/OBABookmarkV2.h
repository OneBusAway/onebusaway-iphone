@class OBABookmarkGroup;
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface OBABookmarkV2 : NSObject<NSCoding>
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *stopID;
@property(nonatomic,strong,nullable) OBABookmarkGroup *group;
@property(nonatomic,assign) NSInteger regionIdentifier;
@end

NS_ASSUME_NONNULL_END

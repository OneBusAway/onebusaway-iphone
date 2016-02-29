@class OBABookmarkGroup;
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface OBABookmarkV2 : NSObject<NSCoding>
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *stopID;
@property(nonatomic,copy) NSString *routeShortName;
@property(nonatomic,strong,nullable) OBABookmarkGroup *group;
@end

NS_ASSUME_NONNULL_END

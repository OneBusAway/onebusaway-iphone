@class OBABookmarkGroup;

@interface OBABookmarkV2 : NSObject

- (id) initWithCoder:(NSCoder*)coder;

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSArray * stopIds;
@property (nonatomic, strong) OBABookmarkGroup *group;

@end

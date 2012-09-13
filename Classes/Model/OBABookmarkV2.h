@interface OBABookmarkV2 : NSObject {
	NSString * _name;
	NSArray * _stopIds;
}

- (id) initWithCoder:(NSCoder*)coder;

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSArray * stopIds;

@end

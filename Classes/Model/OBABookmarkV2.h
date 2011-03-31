@interface OBABookmarkV2 : NSObject {
	NSString * _name;
	NSArray * _stopIds;
}

- (id) initWithCoder:(NSCoder*)coder;

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSArray * stopIds;

@end

@interface OBAStopAccessEventV2 : NSObject <NSCoding> {
	NSString * _title;
	NSString * _subtitle;
	NSArray * _stopIds;
}

- (id) initWithCoder:(NSCoder*)coder;

@property (nonatomic,retain) NSString * title;
@property (nonatomic,retain) NSString * subtitle;
@property (nonatomic, retain) NSArray * stopIds;

@end

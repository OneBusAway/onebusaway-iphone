@interface OBAStopAccessEventV2 : NSObject <NSCoding> {

}

- (id) initWithCoder:(NSCoder*)coder;

@property (nonatomic,strong) NSString * title;
@property (nonatomic,strong) NSString * subtitle;
@property (nonatomic, strong) NSArray * stopIds;

@end

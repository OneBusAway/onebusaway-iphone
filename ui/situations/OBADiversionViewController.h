#import "OBAApplicationDelegate.h"
#import "OBATripDetailsV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBADiversionViewController : UIViewController <MKMapViewDelegate> 

+(OBADiversionViewController*) loadFromNibWithappDelegate:(OBAApplicationDelegate*)context;

@property (nonatomic,strong) IBOutlet OBAApplicationDelegate * appDelegate;
@property (nonatomic,strong) NSString * diversionPath;
@property (nonatomic,strong) NSDictionary * args;

@end

NS_ASSUME_NONNULL_END
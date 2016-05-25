#import <UIKit/UIKit.h>
#import "OBAStaticTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OBATripDetailsV2;
@class OBATripInstanceRef;

@interface OBATripScheduleListViewController : OBAStaticTableViewController
@property(nonatomic,strong) OBATripDetailsV2 *tripDetails;
@property(nonatomic,copy) NSString *currentStopId;

- (instancetype)initWithTripInstance:(OBATripInstanceRef *)tripInstance;
@end

NS_ASSUME_NONNULL_END
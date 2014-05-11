#import "OBAModelService.h"

@interface OBAModelServiceRequest : NSObject<OBAModelServiceRequest,OBADataSourceDelegate>

@property(strong) OBAModelFactory * modelFactory;
@property(assign) SEL modelFactorySelector;

@property BOOL checkCode;

@property UIBackgroundTaskIdentifier bgTask;
@property(strong) id<OBADataSourceConnection> connection;

- (void)endBackgroundTask;
- (void)handleResult:(id)obj;

@end

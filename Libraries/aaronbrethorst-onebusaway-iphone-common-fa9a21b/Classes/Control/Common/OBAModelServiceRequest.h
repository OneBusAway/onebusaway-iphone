#import "OBAModelService.h"

@interface OBAModelServiceRequest : NSObject<OBAModelServiceRequest>

@property(strong) OBAModelFactory * modelFactory;
@property(assign) SEL modelFactorySelector;

@property BOOL checkCode;

@property UIBackgroundTaskIdentifier bgTask;
@property(strong) id<OBADataSourceConnection> connection;

- (void)endBackgroundTask;

- (void) processData:(id) obj withError:(NSError *) error responseCode:(NSUInteger) code completionBlock:(OBADataSourceCompletion) completion;
@end

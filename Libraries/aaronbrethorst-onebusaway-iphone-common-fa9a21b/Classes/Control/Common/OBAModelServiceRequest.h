#import "OBAModelService.h"

@interface OBAModelServiceRequest : NSObject<OBAModelServiceRequest>

@property(strong) OBAModelFactory * modelFactory;
@property(assign) SEL modelFactorySelector;

@property BOOL checkCode;

@property UIBackgroundTaskIdentifier bgTask;
/**
 *  This has to be weak to avoid retain cycles between the "Connection" object and this service request.  The connection may hold a strong reference 
 *  to this request to perform some post processing on the data.
 */
@property (nonatomic, weak) id<OBADataSourceConnection> connection;

- (void)endBackgroundTask;

- (void) processData:(id) obj withError:(NSError *) error responseCode:(NSUInteger) code completionBlock:(OBADataSourceCompletion) completion;
@end

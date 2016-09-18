#import <OBAKit/OBAKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef UIBackgroundTaskIdentifier(^OBABackgroundTaskCleanup)(UIBackgroundTaskIdentifier task);

@interface OBAModelServiceRequest : NSObject<OBAModelServiceRequest>

@property(strong) OBAModelFactory * modelFactory;
@property(assign, nullable) SEL modelFactorySelector;
@property(copy) OBABackgroundTaskCleanup cleanupBlock;

@property BOOL checkCode;

@property UIBackgroundTaskIdentifier bgTask;
/**
 *  This has to be weak to avoid retain cycles between the "Connection" object and this service request.  The connection may hold a strong reference 
 *  to this request to perform some post processing on the data.
 */
@property (nonatomic, weak) id<OBADataSourceConnection> connection;

- (void) processData:(id) obj withError:(NSError *) error responseCode:(NSUInteger) code completionBlock:(OBADataSourceCompletion) completion;
@end

NS_ASSUME_NONNULL_END

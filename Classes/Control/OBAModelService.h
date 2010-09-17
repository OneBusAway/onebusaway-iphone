#import "OBAReferencesV2.h"
#import "OBAModelFactory.h"
#import "OBADataSourceConfig.h"
#import "OBAJsonDataSource.h"
#import "OBAStopV2.h"

@protocol OBAModelServiceRequest <NSObject>
- (void) cancel;
@end

@protocol OBAModelServiceDelegate <NSObject>
- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context;
@optional
- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context;
- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context;
- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context;
@end




@interface OBAModelService : NSObject {
	OBAReferencesV2 * _references;
	OBAModelFactory * _modelFactory;
	OBAJsonDataSource * _jsonDataSource;
}

- (id) initWithReferences:(OBAReferencesV2*)refs modelFactory:(OBAModelFactory*)modelFactory dataSourceConfig:(OBADataSourceConfig*)dataSourceConfig;

- (id<OBAModelServiceRequest>) requestStopForId:(NSString*)stopId withDelegate:(id<OBAModelServiceDelegate,NSObject>)delegate withContext:(id)context;
- (id<OBAModelServiceRequest>) requestStopWithArrivalsAndDeparturesForId:(NSString*)stopId withMinutesAfter:(NSUInteger)minutesAfter withDelegate:(id<OBAModelServiceDelegate,NSObject>)delegate withContext:(id)context;


@end

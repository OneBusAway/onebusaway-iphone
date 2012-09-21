#import "OBAModelService.h"


@interface OBAModelServiceRequest : NSObject<OBAModelServiceRequest,OBADataSourceDelegate>
{
	id<OBAModelServiceDelegate> _delegate;
	id _context;
	OBAModelFactory * _modelFactory;
	SEL _modelFactorySelector;
	
	BOOL _checkCode;
	
	id<OBADataSourceConnection> _connection;
	UIBackgroundTaskIdentifier _bgTask;
	
	BOOL _clean;
}

@property (nonatomic, assign) id<OBAModelServiceDelegate> delegate;
@property (nonatomic,retain) id context;
@property (nonatomic,retain) OBAModelFactory * modelFactory;
@property (nonatomic) SEL modelFactorySelector;

@property (nonatomic, assign) BOOL checkCode;

@property (nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic,retain) id<OBADataSourceConnection> connection;

- (void) endBackgroundTask;
- (void) handleResult:(id)obj;

@end

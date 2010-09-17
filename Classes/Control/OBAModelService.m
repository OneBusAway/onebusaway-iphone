#import "OBAModelService.h"
#import "UIDeviceExtensions.h"


@interface OBARequestImpl : NSObject<OBAModelServiceRequest,OBADataSourceDelegate>
{
	id<OBAModelServiceDelegate> _delegate;
	id _context;
	OBAModelFactory * _modelFactory;
	SEL _modelFactorySelector;
	
	id<OBADataSourceConnection> _connection;
	UIBackgroundTaskIdentifier _bgTask;
}

@property (nonatomic, assign) id<OBAModelServiceDelegate> delegate;
@property (nonatomic,retain) id context;
@property (nonatomic,retain) OBAModelFactory * modelFactory;
@property (nonatomic) SEL modelFactorySelector;

@property (nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic,retain) id<OBADataSourceConnection> connection;

- (void) endBackgroundTask;
- (void) handleResult:(id)obj;

@end


@interface OBAModelService (Private)

- (OBARequestImpl*) requestWithDelegate:(id<OBAModelServiceDelegate,NSObject>)delegate withContext:(id)context;

@end

@implementation OBAModelService

- (id) initWithReferences:(OBAReferencesV2*)refs modelFactory:(OBAModelFactory*)modelFactory dataSourceConfig:(OBADataSourceConfig*)dataSourceConfig {
	if( self = [super init] ) {
		_references = [refs retain];
		_modelFactory = [modelFactory retain];
		_jsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:dataSourceConfig];
	}
	return self;
}

- (void) dealloc {
	[_references release];
	[_modelFactory release];
	[_jsonDataSource release];
	[super dealloc];
}

- (id<OBAModelServiceRequest>) requestStopForId:(NSString*)stopId withDelegate:(id<OBAModelServiceDelegate,NSObject>)delegate withContext:(id)context {

	OBARequestImpl * request = [self requestWithDelegate:delegate withContext:context];	
	request.modelFactorySelector = @selector(getStopFromJSON:error:);
	
	NSString * url = [NSString stringWithFormat:@"/api/where/stop/%@.json", stopId];	
	request.connection = [_jsonDataSource requestWithPath:url withArgs:@"version=2" withDelegate:request context:nil];
	return request;
}

- (id<OBAModelServiceRequest>) requestStopWithArrivalsAndDeparturesForId:(NSString*)stopId withMinutesAfter:(NSUInteger)minutesAfter withDelegate:(id<OBAModelServiceDelegate,NSObject>)delegate withContext:(id)context {

	OBARequestImpl * request = [self requestWithDelegate:delegate withContext:context];	
	request.modelFactorySelector = @selector(getArrivalsAndDeparturesForStopV2FromJSON:error:);

	NSString *url = [NSString stringWithFormat:@"/api/where/arrivals-and-departures-for-stop/%@.json", stopId];
	NSString * args = [NSString stringWithFormat:@"version=2&minutesAfter=%d",minutesAfter];
	
	request.connection = [_jsonDataSource requestWithPath:url withArgs:args withDelegate:request context:nil];
	return request;
}

@end

@implementation OBAModelService (Private)

- (OBARequestImpl*) requestWithDelegate:(id<OBAModelServiceDelegate,NSObject>)delegate withContext:(id)context {

	OBARequestImpl * request = [[[OBARequestImpl alloc] init] autorelease];
	request.delegate = delegate;
	request.context = context;
	request.modelFactory = _modelFactory;
	
	// if we support background task completion (iOS >= 4.0), allow our requests to complete
	// even if the user switches the foreground application.
	if ([[UIDevice currentDevice] isMultitaskingSupportedSafe]) {
		UIApplication* app = [UIApplication sharedApplication];
		request.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
			[request endBackgroundTask];
		}];
	}
	
	return request;
}

@end



@implementation OBARequestImpl

@synthesize delegate = _delegate;
@synthesize context = _context;
@synthesize modelFactory = _modelFactory;
@synthesize modelFactorySelector = _modelFactorySelector;

@synthesize bgTask = _bgTask;
@synthesize connection = _connection;

- (id) init {
	if( self = [super init] ) {
		if ([[UIDevice currentDevice] isMultitaskingSupportedSafe])
            _bgTask = UIBackgroundTaskInvalid;
	}
	return self;
}

- (void) dealloc {
	[_connection release];
	[_context release];
	[_modelFactory release];
	[super dealloc];
}

- (void) handleResult:(id)obj {

	NSNumber * code = [obj valueForKey:@"code"];
	
	if( code == nil || [code intValue] != 200 ) {
		if( [_delegate respondsToSelector:@selector(requestDidFinish:withCode:context:)] )
			[_delegate requestDidFinish:self withCode:[code intValue] context:_context];
		return;
	}
	
	NSDictionary * data = [obj valueForKey:@"data"];
	NSError * error = nil;
	NSError ** errorRef = &error;
	
	id result = nil;
	
	if( ! [_modelFactory respondsToSelector:_modelFactorySelector] )
		return;
	
	NSMethodSignature * sig = [_modelFactory methodSignatureForSelector:_modelFactorySelector];
	NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
	[invocation setTarget:_modelFactory];
	[invocation setSelector:_modelFactorySelector];
	[invocation setArgument:&data atIndex:2];
	[invocation setArgument:&errorRef atIndex:3];
	[invocation invoke];
	
	if( error ) {
		if( [_delegate respondsToSelector:@selector(requestDidFail:withError:context:)] )
			[_delegate requestDidFail:self withError:error context:_context];
		return;
	}
	
	[invocation getReturnValue:&result];
	[_delegate requestDidFinish:self withObject:result context:_context];
}

// check if we support background task completion; if so, end bg task
- (void) endBackgroundTask {	
	
	if ([[UIDevice currentDevice] isMultitaskingSupportedSafe]) {
		if (_bgTask != UIBackgroundTaskInvalid) {
			UIApplication* app = [UIApplication sharedApplication];
			[app endBackgroundTask:_bgTask];
			_bgTask = UIBackgroundTaskInvalid;   
		}
	}
}
	

#pragma mark OBAModelServiceRequest

- (void) cancel {
	[_connection cancel];
}

#pragma mark OBADataSourceDelegate

- (void) connectionDidFinishLoading:(id<OBADataSourceConnection>)connection withObject:(id)obj context:(id)context {
	[self handleResult:obj];
	[self endBackgroundTask];
}

- (void) connectionDidFail:(id<OBADataSourceConnection>)connection withError:(NSError *)error context:(id)context {
	if( [_delegate respondsToSelector:@selector(requestDidFail:withError:context:)] )	
		[_delegate requestDidFail:self withError:error context:_context];
}

- (void) connection:(id<OBADataSourceConnection>)connection withProgress:(float)progress {
	if( [_delegate respondsToSelector:@selector(request:withProgress:context:)] )
		[_delegate request:self withProgress:progress context:_context];
}

@end


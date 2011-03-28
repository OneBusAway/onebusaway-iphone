#import "OBAModelServiceRequest.h"
#import "UIDeviceExtensions.h"


@interface OBAModelServiceRequest (Private)

- (void) cleanup;

@end


@implementation OBAModelServiceRequest

@synthesize delegate = _delegate;
@synthesize context = _context;
@synthesize modelFactory = _modelFactory;
@synthesize modelFactorySelector = _modelFactorySelector;

@synthesize checkCode = _checkCode;

@synthesize bgTask = _bgTask;
@synthesize connection = _connection;

- (id) init {
	if( self = [super init] ) {
		_checkCode = TRUE;
		if ([[UIDevice currentDevice] isMultitaskingSupportedSafe])
            _bgTask = UIBackgroundTaskInvalid;
		
		/**
		 * Why do we retain ourselves?  Many client apps will release their reference to us
		 * in the delegate methods.  To make sure we stick around long enough to perform cleanup,
		 * we keep a reference to ourselves that we'll release in the cleanup phase.
		 */
		_clean = FALSE;
		[self retain];		
	}
	return self;
}

- (void) dealloc {
	[self endBackgroundTask];
	[_connection release];
	[_context release];
	[_modelFactory release];
	[super dealloc];
}

- (void) handleResult:(id)obj {
	
	if( _checkCode ) {
		NSNumber * code = [obj valueForKey:@"code"];
	
		if( code == nil || [code intValue] != 200 ) {
			if( [_delegate respondsToSelector:@selector(requestDidFinish:withCode:context:)] )
				[_delegate requestDidFinish:self withCode:[code intValue] context:_context];
			return;
		}
		
		obj = [obj valueForKey:@"data"];
	}
	
	NSDictionary * data = obj;
	NSError * error = nil;
	NSError ** errorRef = &error;
	
	id result = obj;
	
	if( _modelFactorySelector && [_modelFactory respondsToSelector:_modelFactorySelector] ) {
	
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
	}
	
	
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
	[self cleanup];
}

#pragma mark OBADataSourceDelegate

- (void) connectionDidFinishLoading:(id<OBADataSourceConnection>)connection withObject:(id)obj context:(id)context {
	[self handleResult:obj];
	[self cleanup];
}

- (void) connectionDidFail:(id<OBADataSourceConnection>)connection withError:(NSError *)error context:(id)context {
	if( [_delegate respondsToSelector:@selector(requestDidFail:withError:context:)] )	
		[_delegate requestDidFail:self withError:error context:_context];
	[self cleanup];
}

- (void) connection:(id<OBADataSourceConnection>)connection withProgress:(float)progress {
	if( [_delegate respondsToSelector:@selector(request:withProgress:context:)] )
		[_delegate request:self withProgress:progress context:_context];
}

@end


@implementation OBAModelServiceRequest (Private)

- (void) cleanup {
	if( _clean )
		return;
	_clean = TRUE;
	[self endBackgroundTask];
	[self release];
}

@end


#import "OBAModelServiceRequest.h"

@interface OBAModelServiceRequest ()
@property BOOL clean;
- (void)cleanup;
@end

@implementation OBAModelServiceRequest

- (id) init {
    self = [super init];
	if (self) {
		self.checkCode = YES;
        self.bgTask = UIBackgroundTaskInvalid;
		
        // TODO: AB 20 Sept 12: this comment terrifies me, especially given that this code has moved to ARC.
		/**
		 * Why do we retain ourselves?  Many client apps will release their reference to us
		 * in the delegate methods.  To make sure we stick around long enough to perform cleanup,
		 * we keep a reference to ourselves that we'll release in the cleanup phase.
		 */
		self.clean = NO;
        //[self retain];
	}
	return self;
}

- (void) dealloc {
	[self endBackgroundTask];
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
	
	__unsafe_unretained NSDictionary * data = obj;
	
    // http://stackoverflow.com/questions/10002538/nsinvocation-nserror-autoreleasing-memory-crasher
    __autoreleasing NSError * error = nil;
    __autoreleasing NSError **errorRef = &error;
    
    
	__unsafe_unretained id result = obj;
    
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
	if ([[UIDevice currentDevice] isMultitaskingSupported]) {
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

- (void) cleanup {
    @synchronized(self) {
        if (self.clean) {
            return;
        }
        self.clean = YES;
        [self endBackgroundTask];
        //TODO: the prior existence of this terrifies me. See comment above in -init.
        //	[self release];
    }
}

@end


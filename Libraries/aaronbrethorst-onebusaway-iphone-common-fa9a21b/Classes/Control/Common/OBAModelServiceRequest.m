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

- (void)handleResult:(id)obj {
	
	if (self.checkCode) {
		NSNumber *code = [obj valueForKey:@"code"];
	
		if (!code || 200 != [code integerValue]) {
			if ([_delegate respondsToSelector:@selector(requestDidFinish:withCode:context:)]) {
                [_delegate requestDidFinish:self withCode:[code intValue] context:_context];
            }
				
			return;
		}
		
		obj = [obj valueForKey:@"data"];
	}
	
	NSDictionary * data = obj;
    NSError * error = nil;
	id result = obj;
    
	if (_modelFactorySelector && [_modelFactory respondsToSelector:_modelFactorySelector]) {
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        result = [_modelFactory performSelector:_modelFactorySelector withObject:data withObject:error];
#pragma clang diagnostic pop

		if( error ) {
			if( [_delegate respondsToSelector:@selector(requestDidFail:withError:context:)] )
				[_delegate requestDidFail:self withError:error context:_context];
			return;
		}
	}

	[_delegate requestDidFinish:self withObject:result context:_context];
}

- (void)endBackgroundTask {
    if (_bgTask != UIBackgroundTaskInvalid) {
        UIApplication* app = [UIApplication sharedApplication];
        [app endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
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


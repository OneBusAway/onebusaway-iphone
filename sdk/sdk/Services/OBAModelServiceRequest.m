#import "OBAModelServiceRequest.h"

@interface OBAModelServiceRequest ()
@property BOOL clean;
- (void)cleanup;
@end

@implementation OBAModelServiceRequest

- (id)init {
    self = [super init];

    if (self) {
        self.checkCode = YES;
        self.bgTask = UIBackgroundTaskInvalid;
        self.clean = NO;
    }

    return self;
}

- (void)dealloc {
    [self endBackgroundTask];
}

- (void)processData:(id)obj withError:(NSError *)error responseCode:(NSUInteger)code completionBlock:(OBADataSourceCompletion)completion {
    NSUInteger responseCode = code;

    if (self.checkCode && [obj respondsToSelector:@selector(valueForKey:)]) {
        NSNumber *code = [obj valueForKey:@"code"];

        if (code) {
            responseCode = [code unsignedIntegerValue];
        }

        obj = [obj valueForKey:@"data"];
    }

    NSDictionary *data = obj;
    NSError *jsonError = nil;
    id result = obj;

    if (_modelFactorySelector && [_modelFactory respondsToSelector:_modelFactorySelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        result = [_modelFactory performSelector:_modelFactorySelector withObject:data withObject:jsonError];
#pragma clang diagnostic pop

        if (!error) {
            error = jsonError;
        }
    }

    [self cleanup];

    completion(result, responseCode, error);
}

- (void)endBackgroundTask {
    /**
     TODO - SDK
    if (_bgTask != UIBackgroundTaskInvalid) {
        UIApplication *app = [UIApplication sharedApplication];
        [app endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }
     */
}

#pragma mark OBAModelServiceRequest

- (void)cancel {
    [_connection cancel];
    [self cleanup];
}

- (void)cleanup {
    if (self.clean) {
        return;
    }

    self.clean = YES;
    [self endBackgroundTask];
}

@end

#import "MKMapSnapshotter+AnyPromise.h"


@implementation MKMapSnapshotter (PromiseKit)

- (AnyPromise *)start {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
            resolve(error ?: snapshot);
        }];
    }];
}

@end

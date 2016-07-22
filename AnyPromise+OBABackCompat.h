//
//  AnyPromise+OBABackCompat.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <PromiseKit/PromiseKit.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
@interface AnyPromise (OBABackCompat)
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))finally;
@end
#endif

//
//  AnyPromise+OBABackCompat.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "AnyPromise+OBABackCompat.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0

@implementation AnyPromise (OBABackCompat)

- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))finally {
    return [self always];
}

@end

#endif

//
//  NSArray+OBAAdditions.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/16/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/NSArray+OBAAdditions.h>

@implementation NSArray (OBAAdditions)

- (NSArray*)oba_pickFirst:(NSUInteger)count
{
    if (self.count == 0)
    {
        return self;
    }

    if (self.count < count)
    {
        count = self.count;
    }

    return [self subarrayWithRange:NSMakeRange(0, count)];
}

- (NSArray*)oba_subarrayFromIndex:(NSUInteger)index {
    if (index >= self.count) {
        return @[];
    }

    return [self subarrayWithRange:NSMakeRange(index, self.count - index)];
}

@end

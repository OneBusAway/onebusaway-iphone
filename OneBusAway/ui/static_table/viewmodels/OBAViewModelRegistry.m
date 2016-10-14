//
//  OBAViewModelRegistry.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAViewModelRegistry.h"

static NSMutableArray *registry = nil;

@implementation OBAViewModelRegistry

+ (void)registerClass:(Class)klass {
    if (!registry) {
        registry = [[NSMutableArray alloc] init];
    }

    [registry addObject:klass];
}

+ (NSArray*)registeredClasses
{
    return [NSArray arrayWithArray:registry];
}
@end

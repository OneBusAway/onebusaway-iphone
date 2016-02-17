//
//  NSArray+OBAAdditions.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/16/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/NSArray.h>

@interface NSArray (OBAAdditions)

- (NSArray*)oba_pickFirst:(NSUInteger)count;

@end

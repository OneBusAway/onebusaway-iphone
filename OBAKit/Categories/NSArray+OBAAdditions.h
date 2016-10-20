//
//  NSArray+OBAAdditions.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/16/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface NSArray (OBAAdditions)

- (NSArray*)oba_pickFirst:(NSUInteger)count;
- (NSArray*)oba_subarrayFromIndex:(NSUInteger)index;
@end

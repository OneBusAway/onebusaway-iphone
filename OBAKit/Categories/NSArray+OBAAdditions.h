//
//  NSArray+OBAAdditions.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/16/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (OBAAdditions)

- (NSArray*)oba_pickFirst:(NSUInteger)count;
- (NSArray*)oba_subarrayFromIndex:(NSUInteger)index;

/**
 Groups the receiver by values of the specified key.
 e.g. if you have an array of objects [{category: clothes, name: socks}, {category: clothes, name: pants}, {category: tools, name: hammer}] and try grouping them on category, you'll end up with: {clothes: [{category: clothes, name: socks}, {category: clothes, name: pants}], tools: [{category: tools, name: hammer}]}
 
 Caution: This method will *not* include objects that return nil for the grouping key.

 @param key The key on which to group the receiver

 @return A dictionary similar to the one described in this method description
 */
- (NSDictionary*)oba_groupByKey:(NSString*)key;
@end

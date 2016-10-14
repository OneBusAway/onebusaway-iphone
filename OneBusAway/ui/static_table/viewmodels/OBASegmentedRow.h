//
//  OBASegmentedRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/12/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"

@interface OBASegmentedRow : OBABaseRow
@property(nonatomic,copy) NSArray<NSString*> *items;
@property(nonatomic,assign) NSUInteger selectedItemIndex;
@property(nonatomic,copy) void (^selectionChange)(NSUInteger selectedIndex);

- (instancetype)initWithSelectionChange:(void(^)(NSUInteger selectedIndex))selectionChange NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithAction:(void (^)())action NS_UNAVAILABLE;
@end

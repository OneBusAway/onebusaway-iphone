//
//  OBABaseRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBABaseRow : NSObject<NSCopying>
@property(nonatomic,copy) void (^action)();

- (instancetype)initWithAction:(void (^)())action NS_DESIGNATED_INITIALIZER;

+ (void)registerViewsWithTableView:(UITableView*)tableView;
+ (NSString*)cellReuseIdentifier;
@end

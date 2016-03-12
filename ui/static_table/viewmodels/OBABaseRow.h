//
//  OBABaseRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBABaseRow : NSObject<NSCopying>

/**
 The action taken (pushing a view controller, etc.) when the row is tapped.
 */
@property(nonatomic,copy) void (^action)();

/**
 The action taken (editing the underlying model, etc.) when the row is tapped while the table is in edit mode.
 */
@property(nonatomic,copy) void (^editAction)();

/**
 This block is provided as a convenience for table views where you can delete models. Since it may be difficult
 to associate your row with a model (due to sorting differences or whatever), this block provides an easy way
 to get back to—and delete—the underlying data.
 */
@property(nonatomic,copy) void (^deleteModel)();

@property(nonatomic,assign) NSUInteger indentationLevel;

- (instancetype)initWithAction:(void (^)())action NS_DESIGNATED_INITIALIZER;

+ (void)registerViewsWithTableView:(UITableView*)tableView;
+ (NSString*)cellReuseIdentifier;
@end

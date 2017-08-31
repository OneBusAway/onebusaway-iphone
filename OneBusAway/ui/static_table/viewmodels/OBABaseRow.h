//
//  OBABaseRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class OBABaseRow;
typedef void (^OBARowAction)(OBABaseRow *row);

@interface OBABaseRow : NSObject<NSCopying>

/**
 The action taken (pushing a view controller, etc.) when the row is tapped.
 */
@property(nonatomic,copy) OBARowAction action;

/**
 The action taken (editing the underlying model, etc.) when the row is tapped while the table is in edit mode.
 */
@property(nonatomic,copy) void (^editAction)(void);

/**
 Optional 'swipe to reveal' buttons for this row.
 */
@property(nullable,nonatomic,copy) NSArray<UITableViewRowAction*> *rowActions;

/**
 Optionally, you can attach the represented model in order to 
 make it easier to change the underlying data. You are responsible
 for setting this in your view controllers.
 */
@property(nullable,nonatomic,weak) id model;

/**
 A data identifier for this row. It will be used by editor-type cells (like OBATextFieldCell)
 as the key associated with the cell's value. To use this feature, set the model
 to be a shared NSMutableDictionary.
 */
@property(nullable,nonatomic,copy) NSString *dataKey;

/**
 This block is provided as a convenience for table views where you can delete models. Since it may be difficult
 to associate your row with a model (due to sorting differences or whatever), this block provides an easy way
 to get back to—and delete—the underlying data.
 */
@property(nonatomic,copy) void (^deleteModel)(OBABaseRow *row);

@property(nonatomic,assign) NSUInteger indentationLevel;

@property(nonatomic,assign) UITableViewCellAccessoryType accessoryType;

- (instancetype)initWithAction:(nullable OBARowAction)action NS_DESIGNATED_INITIALIZER;

+ (void)registerViewsWithTableView:(UITableView*)tableView;

+ (NSString*)cellReuseIdentifier;

/**
 By default, this simply returns the class method of the same name. However,
 this gives you the ability to return different cellReuseIdentifiers based
 upon different configurations of your table row.
 */
@property(nonatomic,copy,null_resettable) NSString *cellReuseIdentifier;
@end

NS_ASSUME_NONNULL_END

//
//  OBAStaticTableViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

@import UIKit;
#import "OBATableSection.h"
#import "OBATableRow.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OBARootViewStyle) {
    OBARootViewStyleNormal = 0,
    OBARootViewStyleBlur,
};

@interface OBAStaticTableViewController : UIViewController
@property(nonatomic,assign) OBARootViewStyle rootViewStyle;
@property(nonatomic,strong,readonly) UITableView *tableView;
@property(nonatomic,strong) NSArray<OBATableSection*> *sections;

/**
 The empty data set treatment requires that the table view's footer view
 never gets directly modified. Instead, set this property and the table
 view's footer will be set with this view when appropriate. (i.e. when
 the empty data set title and description are not visible.)
 */
@property(nonatomic,strong,nullable) UIView *tableFooterView;

/**
 A large label that will be displayed on this view controller when it does not contain any data.
 e.g. "No Recent Stops"
 */
@property(nonatomic,copy,nullable) NSString *emptyDataSetTitle;

/**
 A slightly smaller label that will be displayed on this view controller when it does not contain any data.
 e.g. "Visit a bus stop in the app to make stuff appear here."
 */
@property(nonatomic,copy,nullable) NSString *emptyDataSetDescription;

- (nullable OBABaseRow*)rowAtIndexPath:(NSIndexPath*)indexPath;
- (nullable NSIndexPath*)indexPathForRow:(OBABaseRow*)row;

/**
 n.b. This requires you to set a `deleteModel` block on your row.

 Removes the row at indexPath from section[section].rows[row],
 performs table view row deletion animations, and calls the 
 deleteModel block of the row.
 */
- (void)deleteRowAtIndexPath:(NSIndexPath*)indexPath;

/**
 returns the index path for the row that contains a link
 to the specified model.

 @param model The model for which you want to find an index path.

 @return The located index path
 */
- (nullable NSIndexPath*)indexPathForModel:(id)model;

- (BOOL)replaceRowAtIndexPath:(NSIndexPath*)indexPath withRow:(OBABaseRow*)row;
@end

NS_ASSUME_NONNULL_END

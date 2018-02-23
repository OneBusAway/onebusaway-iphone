//
//  OBAStaticTableViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBABaseRow.h>
#import <OBAKit/OBATableSection.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OBARootViewStyle) {
    OBARootViewStyleNormal = 0,
    OBARootViewStyleBlur,
};

@interface OBAStaticTableViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic,assign) OBARootViewStyle rootViewStyle;
@property(nonatomic,strong,readonly) UITableView *tableView;
@property(nonatomic,strong) NSArray<OBATableSection*> *sections;

/**
 Determines whether the controller displays the animated 'loading' rows at view load. True by default.
 */
@property(nonatomic,assign) BOOL showsLoadingPlaceholderRows;

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

/**
 Vertical offset of the empty data set image, title, and description. Default value is -44.0.
 */
@property(nonatomic,assign) CGFloat emptyDataSetVerticalOffset;

/**
 An optional image displayed above the empty data set title and description.
 */
@property(nonatomic,strong,nullable) UIImage *emptyDataSetImage;

/**
 Reloads the empty data set title, description, and image.
 */
- (void)reloadEmptyDataSet;

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
 Inserts a new row into the table view, optionally with animation.

 @param row An instance or subclass of OBABaseRow that will be inserted into the table's data.
 @param indexPath The index path where the row will be inserted.
 @param animation The desired insertion animation
 */
- (void)insertRow:(OBABaseRow*)row atIndexPath:(NSIndexPath*)indexPath animation:(UITableViewRowAnimation)animation;

/**
 returns the index path for the row that contains a link
 to the specified model.

 @param model The model for which you want to find an index path.

 @return The located index path
 */
- (nullable NSIndexPath*)indexPathForModel:(id)model;

- (BOOL)replaceRowAtIndexPath:(NSIndexPath*)indexPath withRow:(OBABaseRow*)row;

/**
 Displays a few rows of shimmering placeholder cells while content loads.
 */
- (void)displayLoadingUI;

/**
 Dismisses shimmering placeholder cells.
 */
- (void)hideLoadingUI;
@end

NS_ASSUME_NONNULL_END

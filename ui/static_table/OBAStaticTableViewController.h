//
//  OBAStaticTableViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>
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
 A large label that will be displayed on this view controller when it does not contain any data.
 e.g. "No Recent Stops"
 */
@property(nonatomic,copy,nullable) NSString *emptyDataSetTitle;

/**
 A slightly smaller label that will be displayed on this view controller when it does not contain any data.
 e.g. "Visit a bus stop in the app to make stuff appear here."
 */
@property(nonatomic,copy,nullable) NSString *emptyDataSetDescription;

- (OBABaseRow*)rowAtIndexPath:(NSIndexPath*)indexPath;

- (nullable NSIndexPath*)indexPathForRow:(OBABaseRow*)row;
@end

NS_ASSUME_NONNULL_END
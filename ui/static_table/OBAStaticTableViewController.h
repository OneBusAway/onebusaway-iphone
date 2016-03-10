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

@interface OBAStaticTableViewController : UIViewController
@property(nonatomic,strong,readonly) UITableView *tableView;
@property(nonatomic,strong) NSArray<OBATableSection*> *sections;

@end

NS_ASSUME_NONNULL_END
//
//  OBABookmarkGroupsViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBAStaticTableViewController.h"

@class OBAModelDAO;

@interface OBABookmarkGroupsViewController : OBAStaticTableViewController
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@end

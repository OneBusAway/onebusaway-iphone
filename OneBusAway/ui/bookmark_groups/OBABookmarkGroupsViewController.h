//
//  OBABookmarkGroupsViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import "OBAStaticTableViewController.h"

@class OBABookmarkGroup;
@class OBAModelDAO;

@protocol OBABookmarkGroupVCDelegate <NSObject>
@optional
- (void)didSetBookmarkGroup:(nullable OBABookmarkGroup*)group;
@end

@interface OBABookmarkGroupsViewController : OBAStaticTableViewController
@property(nonatomic,assign) BOOL enableGroupEditing;
@property(nonatomic,strong,nullable) OBAModelDAO *modelDAO;
@property(nonatomic,strong,nullable) id<OBABookmarkGroupVCDelegate> delegate;
@end

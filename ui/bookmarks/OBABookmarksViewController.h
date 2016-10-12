//
//  OBABookmarksViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import OBAKit;
#import "OBAStaticTableViewController.h"
#import "OBANavigationTargetAware.h"

@class OBAModelDAO;
@class OBAModelService;

@interface OBABookmarksViewController : OBAStaticTableViewController <OBANavigationTargetAware>
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) OBAModelService *modelService;
@end

//
//  OBABookmarksViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import OBAKit;

@interface OBABookmarksViewController : OBAStaticTableViewController<OBANavigationTargetAware>
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) PromisedModelService *modelService;
@property(nonatomic,strong) OBALocationManager *locationManager;
@end

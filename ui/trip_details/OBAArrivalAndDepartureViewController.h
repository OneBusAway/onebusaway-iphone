//
//  OBAArrivalAndDepartureViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import OBAKit;
#import "OBAStaticTableViewController.h"

@interface OBAArrivalAndDepartureViewController : OBAStaticTableViewController
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) OBAModelService *modelService;
@property(nonatomic,strong) OBAArrivalAndDepartureV2* arrivalAndDeparture;

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;
@end

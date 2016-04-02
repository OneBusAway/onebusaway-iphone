//
//  OBAStaticTableViewController+Builders.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAStaticTableViewController.h"
#import "OBAHasServiceAlerts.h"

@class OBAArrivalsAndDeparturesForStopV2;
@class OBAServiceAlertsModel;

@interface OBAStaticTableViewController (Builders)
+ (OBATableSection*)createServiceAlertsSection:(id<OBAHasServiceAlerts>)result serviceAlerts:(OBAServiceAlertsModel*)serviceAlerts navigationController:(UINavigationController*)navigationController;
@end

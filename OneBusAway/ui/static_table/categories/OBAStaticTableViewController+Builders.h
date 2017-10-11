//
//  OBAStaticTableViewController+Builders.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import OBAKit;

@interface OBAStaticTableViewController (Builders)
- (OBATableSection*)createServiceAlertsSection:(id<OBAHasServiceAlerts>)result serviceAlerts:(OBAServiceAlertsModel*)serviceAlerts;
@end

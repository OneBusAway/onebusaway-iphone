//
//  OBAStaticTableViewController+Builders.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAStaticTableViewController+Builders.h"
#import "OBAServiceAlertsViewController.h"

@implementation OBAStaticTableViewController (Builders)

- (OBATableSection*)createServiceAlertsSection:(id<OBAHasServiceAlerts>)result serviceAlerts:(OBAServiceAlertsModel*)serviceAlerts {
    OBATableRow *serviceAlertsRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_view_service_alerts", @"") action:^{
        OBAServiceAlertsViewController *situations = [[OBAServiceAlertsViewController alloc] initWithSituations:result.situations];
        [self.navigationController pushViewController:situations animated:YES];
    }];
    serviceAlertsRow.style = UITableViewCellStyleValue1;
    serviceAlertsRow.subtitle = [@(serviceAlerts.unreadCount) description];
    serviceAlertsRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    serviceAlertsRow.image = [self.class iconForServiceAlerts:serviceAlerts];

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:@[serviceAlertsRow]];
    return section;
}

+ (UIImage*)iconForServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts {
    if (serviceAlerts.unreadCount > 0) {
        return [UIImage imageNamed:@"warning_filled"];
    }
    else {
        return [UIImage imageNamed:@"warning"];
    }
}
@end

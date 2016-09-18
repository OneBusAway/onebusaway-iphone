//
//  OBAStaticTableViewController+Builders.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAStaticTableViewController+Builders.h"
#import "OBASituationsViewController.h"

@implementation OBAStaticTableViewController (Builders)

+ (OBATableSection*)createServiceAlertsSection:(id<OBAHasServiceAlerts>)result serviceAlerts:(OBAServiceAlertsModel*)serviceAlerts navigationController:(UINavigationController*)navigationController {
    OBATableRow *serviceAlertsRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"View Service Alerts", @"") action:^{
        [OBASituationsViewController showSituations:result.situations navigationController:navigationController args:nil];
    }];

    serviceAlertsRow.image = [self.class iconForServiceAlerts:serviceAlerts];

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:@[serviceAlertsRow]];
    return section;
}

+ (UIImage*)iconForServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts {
    if (serviceAlerts.unreadCount > 0) {
        NSString *imageName = [serviceAlerts.unreadMaxSeverity isEqual:@"noImpact"] ? @"Alert-Info" : @"Alert";
        return [UIImage imageNamed:imageName];
    }
    else {
        NSString *imageName = [serviceAlerts.maxSeverity isEqual:@"noImpact"] ? @"Alert-Info-Grayscale" : @"AlertGrayscale";
        return [UIImage imageNamed:imageName];
    }
}
@end

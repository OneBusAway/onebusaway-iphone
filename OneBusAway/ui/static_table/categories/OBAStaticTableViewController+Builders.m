//
//  OBAStaticTableViewController+Builders.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAStaticTableViewController+Builders.h"
#import "OBAAnalytics.h"

@implementation OBAStaticTableViewController (Builders)

- (OBATableSection*)createServiceAlertsSection:(id<OBAHasServiceAlerts>)result serviceAlerts:(OBAServiceAlertsModel*)serviceAlerts modelDAO:(OBAModelDAO*)modelDAO situationSelected:(void(^)(OBASituationV2 *situation))situationSelected {

    NSMutableArray *rows = [[NSMutableArray alloc] init];

    for (OBASituationV2 *situation in result.situations) {
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:situation.summary action:^(OBABaseRow *r) {
            [modelDAO setVisited:YES forSituationWithId:situation.situationId];
            [self reportAnalytics:situation];
            situationSelected(situation);
        }];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        if ([modelDAO isVisitedSituationWithId:situation.situationId]) {
            row.image = [UIImage imageNamed:@"warning"];
            row.titleFont = OBATheme.bodyFont;
        }
        else {
            row.image = [UIImage imageNamed:@"warning_filled"];
            row.titleFont = OBATheme.boldBodyFont;
        }

        [rows addObject:row];
    }

    return [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"msg_service_alerts",) rows:rows];
}

- (void)reportAnalytics:(OBASituationV2 *)situation {
    NSDictionary *agencies = situation.references.agencies;
    for (id key in agencies) {
        OBAAgencyV2 * agency = agencies[key];
        [OBAAnalytics.sharedInstance reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"service_alerts" label:[NSString stringWithFormat:@"Clicked Service Alerts from: %@", agency.name] value:nil];
        [FIRAnalytics logEventWithName:OBAAnalyticsServiceAlertTapped parameters:@{@"agencyName": agency.name, @"situationID": situation.situationId}];
    }
}

@end

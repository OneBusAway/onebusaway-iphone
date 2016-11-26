//
//  OBAServiceAlertsViewController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 11/17/10.
//  Copyright 2010 OneBusAway. All rights reserved.
//

#import "OBAServiceAlertsViewController.h"
#import "OBAAnalytics.h"
#import "OBAEmptyDataSetSource.h"
#import "EXTScope.h"
#import "OneBusAway-Swift.h"

@interface OBAServiceAlertsViewController ()
@property(nonatomic,copy) NSArray<OBASituationV2*> *situations;
@end

@implementation OBAServiceAlertsViewController

#pragma mark - Initialization

- (instancetype) initWithSituations:(NSArray*)situations {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _situations = situations;
        self.title = NSLocalizedString(@"msg_service_alerts",);
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];

    OBAEmptyDataSetSource *emptyDataSource = [[OBAEmptyDataSetSource alloc] initWithTitle:NSLocalizedString(@"msg_no_active_service_alerts",) description:nil];
    self.tableView.emptyDataSetSource = emptyDataSource;
}

#pragma mark - Lazy Loading

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.situations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBASituationV2 * situation = self.situations[indexPath.row];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"identifier"];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"identifier"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
    }

    UIFont *font = nil;
    if ([self.modelDAO isVisitedSituationWithId:situation.situationId]) {
        font = [OBATheme bodyFont];
    }
    else {
        font = [OBATheme boldBodyFont];
    }
    cell.textLabel.font = font;

    cell.textLabel.text = situation.summary;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OBASituationV2 * situation = self.situations[indexPath.row];

    [self reportAnalytics:situation];

    [self.modelDAO setVisited:YES forSituationWithId:situation.situationId];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    ServiceAlertDetailsViewController *details = [[ServiceAlertDetailsViewController alloc] initWithServiceAlert:situation];
    [self.navigationController pushViewController:details animated:YES];
}

#pragma mark - Private

- (void)reportAnalytics:(OBASituationV2 *) situation {
    NSDictionary *agencies = [situation.references getAllAgencies];
    for (id key in agencies) {
        OBAAgencyV2 * agency = agencies[key];
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"service_alerts" label:[NSString stringWithFormat:@"Clicked Service Alerts from: %@", agency.name] value:nil];
    }
}

@end

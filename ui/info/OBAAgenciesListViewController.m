#import "OBAAgenciesListViewController.h"
#import "OBALogger.h"
#import "OBAPresentation.h"
#import "OBAAgencyWithCoverageV2.h"
#import "OBASearch.h"
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
@import SafariServices;

typedef NS_ENUM (NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeActions,
    OBASectionTypeAgencies,
    OBASectionTypeNoAgencies,
};

@interface OBAAgenciesListViewController ()

@property (nonatomic, strong) NSMutableArray *agencies;

@end

@implementation OBAAgenciesListViewController

- (id)init {
    self = [super initWithApplicationDelegate:APP_DELEGATE];

    if (self) {
        self.title = NSLocalizedString(@"Agencies", @"Agencies tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Agencies"];
        self.refreshable = NO;
        self.showUpdateTime = NO;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.refreshable = NO;
    self.showUpdateTime = NO;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (BOOL)isLoading {
    return self.agencies == nil;
}

- (id<OBAModelServiceRequest>)handleRefresh {
    @weakify(self);
    return [[OBAApplication sharedApplication].modelService requestAgenciesWithCoverage:^(id jsonData, NSUInteger responseCode, NSError *error) {
        @strongify(self);
        
        if (error) {
            [self refreshFailedWithError:error];
        }
        else {
            OBAListWithRangeAndReferencesV2 *list = jsonData;
            self.agencies = [[NSMutableArray alloc] initWithArray:list.values];
            [self.agencies sortUsingSelector:@selector(compareUsingAgencyName:)];
            self.progressLabel = NSLocalizedString(@"Agencies", @"");
            [self refreshCompleteWithCode:responseCode];
        }
    }];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self isLoading]) {
        return [super numberOfSectionsInTableView:tableView];
    }

    if (self.agencies.count == 0) {
        return 1;
    }
    else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isLoading]) {
        return [super tableView:tableView numberOfRowsInSection:section];
    }

    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeActions:
            return 1;

        case OBASectionTypeAgencies:
            return self.agencies.count;

        case OBASectionTypeNoAgencies:
            return 1;

        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLoading]) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }

    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeActions:
            return [self actionsCellForRowAtIndexPath:indexPath tableView:tableView];

        case OBASectionTypeAgencies:
            return [self agenciesCellForRowAtIndexPath:indexPath tableView:tableView];

        case OBASectionTypeNoAgencies:
            return [self noAgenciesCellForRowAtIndexPath:indexPath tableView:tableView];

        default:
            break;
    }

    return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLoading]) {
        return;
    }

    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeActions:
            [self didSelectActionsRowAtIndexPath:indexPath tableView:tableView];
            break;

        case OBASectionTypeAgencies:
            [self didSelectAgencyRowAtIndexPath:indexPath tableView:tableView];
            break;

        default:
            break;
    }
}

- (OBASectionType)sectionTypeForSection:(NSUInteger)section {
    if (self.agencies.count == 0) {
        if (section == 0) {
            return OBASectionTypeNoAgencies;
        }
    }
    else {
        if (section == 0) {
            return OBASectionTypeActions;
        }
        else if (section == 1) {
            return OBASectionTypeAgencies;
        }
    }

    return OBASectionTypeNone;
}

- (UITableViewCell *)actionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = NSLocalizedString(@"Show on Map", @"AgenciesListViewController");
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
     if (section == 0) {
        UIView *footer = [[UIView alloc] init];
        footer.backgroundColor = OBAGREENBACKGROUND;
        return footer;
    }
    else {
        return nil;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 33;
    }
    else return 0;
}
- (UITableViewCell *)agenciesCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {

    OBAAgencyWithCoverageV2 *awc = self.agencies[indexPath.row];
    OBAAgencyV2 *agency = awc.agency;

    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.textLabel.text = agency.name;
    return cell;
}

- (UITableViewCell *)noAgenciesCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = NSLocalizedString(@"No agencies found", @"cell.textLabel.text");
    return cell;
}

- (void)didSelectActionsRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBANavigationTarget *target = [OBASearch getNavigationTargetForSearchAgenciesWithCoverage];

    [self.appDelegate navigateToTarget:target];
}

- (void)didSelectAgencyRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBAAgencyWithCoverageV2 *awc = self.agencies[indexPath.row];
    OBAAgencyV2 *agency = awc.agency;
    NSURL *url = [NSURL URLWithString:agency.url];
    SFSafariViewController *svc = [[SFSafariViewController alloc]initWithURL:url];
    [self presentViewController:svc animated:YES completion:nil];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

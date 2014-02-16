#import "OBAAgenciesListViewController.h"
#import "OBALogger.h"
#import "OBAPresentation.h"
#import "OBAAgencyWithCoverageV2.h"
#import "OBASearch.h"


typedef enum {
    OBASectionTypeNone,
    OBASectionTypeActions,
    OBASectionTypeAgencies,
    OBASectionTypeNoAgencies,
} OBASectionType;


@interface OBAAgenciesListViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell*) actionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) agenciesCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) noAgenciesCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;

- (void) didSelectActionsRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void) didSelectAgencyRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

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

-(void) viewDidLoad {
    [super viewDidLoad];
    self.refreshable = NO;
    self.showUpdateTime = NO;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
}
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (BOOL) isLoading {
    return _agencies == nil;
}

- (id<OBAModelServiceRequest>) handleRefresh {
    return [_appDelegate.modelService requestAgenciesWithCoverageWithDelegate:self withContext:nil];
}

-(void) handleData:(id)obj context:(id)context {
    OBAListWithRangeAndReferencesV2 * list = obj;
    _agencies = [[NSMutableArray alloc] initWithArray:list.values];
    [_agencies sortUsingSelector:@selector(compareUsingAgencyName:)];
    _progressLabel = @"Agencies";
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if( [self isLoading] )
        return [super numberOfSectionsInTableView:tableView];

    if ([_agencies count] == 0)
        return 1;
    else
        return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if( [self isLoading] )
        return [super tableView:tableView numberOfRowsInSection:section];
    
    OBASectionType sectionType = [self sectionTypeForSection:section];
    
    switch( sectionType ) {
        case OBASectionTypeActions:
            return 1;
        case OBASectionTypeAgencies:
            return [_agencies count] + 1;
        case OBASectionTypeNoAgencies:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( [self isLoading] )
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
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
    
    if( [self isLoading] ) {
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

@end


@implementation OBAAgenciesListViewController (Private)


- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
    
    if( [_agencies count] == 0 ) {
        if( section == 0 )
            return OBASectionTypeNoAgencies;
    }
    else {
        if( section == 0 )
            return OBASectionTypeActions;
        else if( section == 1 )
            return OBASectionTypeAgencies;
    }
    
    return OBASectionTypeNone;
}

- (UITableViewCell*) actionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.text = NSLocalizedString(@"Show on map",@"AgenciesListViewController");
    return cell;
}

- (UITableViewCell*) agenciesCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {

    if (indexPath.row == 0) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        cell.backgroundView.backgroundColor = OBAGREENBACKGROUND;
        return cell;
    }
    OBAAgencyWithCoverageV2 * awc = _agencies[indexPath.row-1];
    OBAAgencyV2 * agency = awc.agency;
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.textLabel.text = agency.name;
    return cell;
}

- (UITableViewCell*) noAgenciesCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.textLabel.text = NSLocalizedString(@"No agencies found",@"cell.textLabel.text");
    return cell;    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([self sectionTypeForSection:indexPath.section]) {
        case OBASectionTypeAgencies:
            if (indexPath.row == 0) {
                return 30;
            }
        default:
            return 44;
    }

}

- (void) didSelectActionsRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchAgenciesWithCoverage];
    [_appDelegate navigateToTarget:target];
}

- (void) didSelectAgencyRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    if (indexPath.row == 0) {
        return;
    }
    OBAAgencyWithCoverageV2 * awc = _agencies[indexPath.row-1];
    OBAAgencyV2 * agency = awc.agency;
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: agency.url]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end


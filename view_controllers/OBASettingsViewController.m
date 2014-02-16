//
//  OBASettingsViewController.m
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 11.08.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBASettingsViewController.h"
#import "OBAApplicationDelegate.h"
#import "OBARegionListViewController.h"
#import "UITableViewController+oba_Additions.h"

#define kRegionsSection 0
#define kVersionSection 1

#define kVersionRow 0
#ifdef DEBUG
#    define kTypeRow 1
#endif

@interface OBASettingsViewController ()
@property (nonatomic) OBAApplicationDelegate *appDelegate;
@end

@implementation OBASettingsViewController


- (id)init {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.title = NSLocalizedString(@"Settings", @"");
        self.appDelegate = APP_DELEGATE;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self hideEmptySeparators];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.tableView reloadData];

    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kRegionsSection:
            return NSLocalizedString(@"Region", @"settings region title");
        case kVersionSection:
            return @"";
        default:
            return @"";
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
#ifdef DEBUG
    if (section == kRegionsSection){ 
        return 1;
    }else{
        return 2;
    }
#else
    return 1;
#endif    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    
    switch (indexPath.section) {
        case kRegionsSection: {
            if ([self.appDelegate.modelDao.readCustomApiUrl isEqualToString:@""]) {
                cell.textLabel.text = self.appDelegate.modelDao.region.regionName;
            } else {
                cell.textLabel.text = self.appDelegate.modelDao.readCustomApiUrl;
            }
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case kVersionSection: {
            switch (indexPath.row) {
                case kVersionRow: {
                    cell.textLabel.text = NSLocalizedString(@"App Version", @"settings version");
                    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                    NSString *appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", appVersionString, appBuildString];
                    cell.detailTextLabel.textColor = [UIColor blackColor];
                    cell.textLabel.font = [UIFont systemFontOfSize:18];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
#ifdef DEBUG
                case kTypeRow: {
                    cell.textLabel.text = NSLocalizedString(@"Debug Version", @"Debug Version");
                    cell.textLabel.font = [UIFont systemFontOfSize:18];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
#endif
                default:
                    break;
            }
        }
        default:
            break;
    }
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UIViewController *pushMe = nil;

    switch (indexPath.section) {
        case kRegionsSection: {
            pushMe = [[OBARegionListViewController alloc] initWithApplicationDelegate:self.appDelegate];
            break;
        }
        default:
            return;
    }
    
    [self.navigationController pushViewController:pushMe animated:YES];

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kRegionsSection:
            return 40;
        case kVersionSection:
        default:
            return 30;
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    view.backgroundColor = OBAGREENBACKGROUND;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
    title.font = [UIFont systemFontOfSize:18];
    title.backgroundColor = [UIColor clearColor];;
    switch (section) {
        case kRegionsSection:
            title.text = NSLocalizedString(@"Region", @"settings region title");
            break;
        case kVersionSection:
        default:
            break;
    }
    [view addSubview:title];
    return view;
}
@end

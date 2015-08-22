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
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAListSelectionViewController.h"

#define kRegionsSection       0
#define kMapTypeSection       1
#define kAccessibilitySection 2
#define kVersionSection       3

#define kVersionRow           0
#ifdef DEBUG
#    define kTypeRow          1
#endif

#define mapTypeStandardIndex  0
#define mapTypeHybridIndex    1
#define mapTypeSatelliteIndex 2

static NSString *kOBAIncreaseContrastKey = @"OBAIncreaseContrastDefaultsKey";
static NSString *kOBAMapTypeKey = @"OBAMapTypeDefaultsKey";

@interface OBASettingsViewController () <OBAListSelectionViewControllerDelegate>
@property (nonatomic) OBAApplicationDelegate *appDelegate;
@property (nonatomic, strong) UISwitch *toggleSwitch;
@property (nonatomic, assign) BOOL increaseContrast;
@property (nonatomic, assign) MKMapType mapType;
@end

@implementation OBASettingsViewController


- (id)init {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.title = NSLocalizedString(@"Settings", @"");
        self.appDelegate = APP_DELEGATE;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self hideEmptySeparators];

    self.increaseContrast = [[NSUserDefaults standardUserDefaults] boolForKey:kOBAIncreaseContrastKey];
    self.mapType = [[NSUserDefaults standardUserDefaults] integerForKey:kOBAMapTypeKey];

    self.toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [self.toggleSwitch setOn:self.increaseContrast animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didSwitchStateOfToggle:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kOBAIncreaseContrastKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:OBAIncreaseContrastToggledNotification object:nil userInfo:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // Why is this here? This is superseded by tableView:viewForHeaderInSection:
    switch (section) {
        case kRegionsSection:
            return NSLocalizedString(@"Region", @"settings region title");
        case kMapTypeSection:
            return NSLocalizedString(@"Map Type", @"map type");

        case kAccessibilitySection:
            return @"";

        case kVersionSection:
            return @"";

        default:
            return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
#ifdef DEBUG

    if (section == kRegionsSection) {
        return 1;
    }
    else if (section == kMapTypeSection) {
        return 1;
    }
    else if (section == kAccessibilitySection) {
        return 1;
    }
    else {
        return 2;
    }

#else
    return 1;

#endif
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }

    switch (indexPath.section) {
        case kRegionsSection: {
            if ([[OBAApplication sharedApplication].modelDao.readCustomApiUrl isEqualToString:@""]) {
                cell.textLabel.text = [OBAApplication sharedApplication].modelDao.region.regionName;
            }
            else {
                cell.textLabel.text = [OBAApplication sharedApplication].modelDao.readCustomApiUrl;
            }

            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }

        case kMapTypeSection: {
            cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"mapTypeCell"];


            self.mapType = [[NSUserDefaults standardUserDefaults] integerForKey:kOBAMapTypeKey];
            if (self.mapType == MKMapTypeStandard) {
                cell.textLabel.text = NSLocalizedString(@"Standard", @"settings standard map type");;

            } else if (self.mapType == MKMapTypeHybrid) {
                cell.textLabel.text = NSLocalizedString(@"Hybrid", @"settings hybrid map type");

            } else {
                cell.textLabel.text = NSLocalizedString(@"Satellite", @"settings satellite map type");

            }

            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }

        case kAccessibilitySection: {
            cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"IncreaseContrastCell"];

            [self.toggleSwitch
             addTarget:self
                          action:@selector(didSwitchStateOfToggle:)
                forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = [[UIView alloc] initWithFrame:self.toggleSwitch.frame];
            [cell.accessoryView addSubview:self.toggleSwitch];

            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.textLabel.text = NSLocalizedString(@"Increase Contrast", @"increase contrast");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UIViewController *pushMe = nil;

    switch (indexPath.section) {
        case kRegionsSection: {
            pushMe = [[OBARegionListViewController alloc] initWithApplicationDelegate:self.appDelegate];
            break;
        }
        case kMapTypeSection: {
            NSString *standard = NSLocalizedString(@"Standard", @"settings standard map type");
            NSString *hybrid = NSLocalizedString(@"Hybrid", @"settings hybrid map type");
            NSString *satellite = NSLocalizedString(@"Satellite", @"settings satellite map type");
            NSArray *possibleValues = [NSArray arrayWithObjects:standard, hybrid, satellite, nil];

            NSIndexPath *selectedIndex;
            self.mapType = [[NSUserDefaults standardUserDefaults] integerForKey:kOBAMapTypeKey];
            if (self.mapType == MKMapTypeStandard) {
                selectedIndex = [NSIndexPath indexPathForRow:mapTypeStandardIndex inSection:0];
            } else if (self.mapType == MKMapTypeHybrid) {
                selectedIndex = [NSIndexPath indexPathForRow:mapTypeHybridIndex inSection:0];
            } else {
                selectedIndex = [NSIndexPath indexPathForRow:mapTypeSatelliteIndex inSection:0];
            }

            OBAListSelectionViewController* vc = [[OBAListSelectionViewController alloc] initWithValues:possibleValues
                                                     selectedIndex:selectedIndex];
            vc.delegate = self;
            pushMe = vc;
            break;
        }
        default:
            return;
    }

    [self.navigationController pushViewController:pushMe animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case kRegionsSection:
        case kMapTypeSection:
            return 40;

        case kVersionSection:
        default:
            return 30;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];

    view.backgroundColor = OBAGREENBACKGROUND;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
    title.font = [UIFont systemFontOfSize:18];
    title.backgroundColor = [UIColor clearColor];
    switch (section) {
        case kRegionsSection:
            title.text = NSLocalizedString(@"Region", @"settings region title");
            break;
        case kMapTypeSection:
            title.text = NSLocalizedString(@"Map Type", @"settings map type title");
            break;
        case kVersionSection:
        default:
            break;
    }
    [view addSubview:title];
    return view;
}

#pragma mark - List selection view delegate
- (void)checkItemWithIndex:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case mapTypeStandardIndex: {
                [[NSUserDefaults standardUserDefaults] setInteger:MKMapTypeStandard
                                                           forKey:kOBAMapTypeKey];
                break;
            }
            case mapTypeHybridIndex: {
                [[NSUserDefaults standardUserDefaults] setInteger:MKMapTypeHybrid
                                                           forKey:kOBAMapTypeKey];
                break;
            }
            case mapTypeSatelliteIndex: {
                [[NSUserDefaults standardUserDefaults] setInteger:MKMapTypeSatellite
                                                           forKey:kOBAMapTypeKey];
                break;
            }
            default:
                break;
        }
        [[NSNotificationCenter defaultCenter]postNotificationName:@"OBAMapTypeChangedNotification" object:nil];
    }

}
@end

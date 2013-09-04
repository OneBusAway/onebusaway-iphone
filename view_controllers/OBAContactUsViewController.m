/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAContactUsViewController.h"
#import "UITableViewController+oba_Additions.h"

static NSString *kOBADefaultContactEmail = @"contact@onebusaway.org";
static NSString *kOBADefaultTwitterURL = @"http://twitter.com/onebusaway";



@implementation OBAContactUsViewController


- (id)init {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.title = NSLocalizedString(@"Contact Us & More", @"Contact us tab title");
        self.appDelegate = APP_DELEGATE;
    }
    return self;
}


#pragma mark UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self hideEmptySeparators];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [TestFlight passCheckpoint:@"OBAContactUsViewController"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        OBARegionV2 *region = _appDelegate.modelDao.region;
        if (region.facebookUrl && ![region.facebookUrl isEqualToString:@""]) {
            return 3;
        }
        return 2;
    } else
    {
        return 4;
    }
}



// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.imageView.image = nil;

    cell.textLabel.font = [UIFont systemFontOfSize:18];
    
    switch( indexPath.row) {
        case 0:
            if (indexPath.section == 0) {
                cell.textLabel.text = NSLocalizedString(@"Email", @"Email title");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Sign up for beta releases",@"cell.textLabel.text case 0");
            }
            break;
        case 1:
            if (indexPath.section == 0) {
                cell.textLabel.text = NSLocalizedString(@"Twitter", @"Twitter title");
            } else {
                cell.textLabel.text = NSLocalizedString(@"OneBusAway issue tracker",@"cell.textLabel.text case 1");
            }
            break;
        case 2:
            if (indexPath.section == 0) {
                cell.textLabel.text = NSLocalizedString(@"Facebook", @"Facebook title");
            } else {
                cell.textLabel.text = NSLocalizedString(@"OneBusAway feature requests",@"cell.textLabel.text case 2");
            }
            break;
        case 3:
            cell.textLabel.text = NSLocalizedString(@"Privacy policy",@"cell.textLabel.text case 3");
            break;

    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OBARegionV2 *region = _appDelegate.modelDao.region;
    switch( indexPath.row) {
        case 0:
            if (indexPath.section == 0) {
                NSString *contactEmail = kOBADefaultContactEmail;
                if (region) {
                    contactEmail = region.contactEmail;
                }
                contactEmail = [NSString stringWithFormat:@"mailto:%@",contactEmail];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: contactEmail]];
            } else
            {
                NSString *url = [NSString stringWithString: NSLocalizedString(@"https://testflightapp.com/join/f3ba0330e6f87e3459f4090bb2adccf0-MjEwOTYz/",@"didSelectRowAtIndexPath case 0")];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
            }
            break;
        case 1:
            if (indexPath.section == 0) {
                NSString *twitterUrl = kOBADefaultTwitterURL;
                if (region) {
                    twitterUrl = region.twitterUrl;
                }
                NSString *twitterName = [[twitterUrl componentsSeparatedByString:@"/"] lastObject];
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
                    NSString *url = [NSString stringWithFormat:@"twitter://user?screen_name=%@",twitterName ];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                } else {
                    NSString *url = [NSString stringWithFormat:@"http://twitter.com/%@", twitterName];
                    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
                }
            } else
            {
                NSString *url = [NSString stringWithString: NSLocalizedString(@"https://github.com/OneBusAway/onebusaway-iphone/issues",@"didSelectRowAtIndexPath case 1")];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];

            }
            break;
        case 2:
            if (indexPath.section == 0 && region.facebookUrl) {
                NSString *facebookUrl = region.facebookUrl;
                NSString *facebookPage = [[facebookUrl componentsSeparatedByString:@"/"] lastObject];

                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]]) {
                    NSString *url = [NSString stringWithFormat:@"fb://profile/%@",facebookPage ];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
                } else {
                    NSString *url = [NSString stringWithFormat:@"http://facebook.com/%@", facebookPage];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
                }
            } else
            {
                NSString *url = [NSString stringWithString: NSLocalizedString(@"http://onebusaway.ideascale.com/a/ideafactory.do?id=8715&mode=top&discussionFilter=byids&discussionID=46166",@"didSelectRowAtIndexPath case 2")];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
            }
            break;
        case 3:
            if (indexPath.section != 0) {
                NSString *url = [NSString stringWithString: NSLocalizedString(@"http://onebusaway.org/privacy/",@"didSelectRowAtIndexPath case 3")];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
            }
            break;
            
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{        
    return 40;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    view.backgroundColor = OBAGREENBACKGROUND;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
    title.font = [UIFont systemFontOfSize:18];
    title.backgroundColor = [UIColor clearColor];;
    switch(section) {
        case 0:
            title.text = NSLocalizedString(@"Contact Us",@"titleForHeaderInSection case 0");
            break;
        case 1:
            title.text = NSLocalizedString(@"More",@"titleForHeaderInSection case 1");
            break;

    }
    [view addSubview:title];
    return view;
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeContactUs];
}

@end


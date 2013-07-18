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
//#import "ISFeedback.h"


@implementation OBAContactUsViewController

@synthesize appContext = _appContext;

- (id)init {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.title = NSLocalizedString(@"Contact Us & More", @"Contact us tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"ContactUs"];
    }
    return self;
}


#pragma mark UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
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
        return 2;
    } else
    {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return NSLocalizedString(@"Contact Us",@"titleForHeaderInSection case 0");
        case 1:
            return NSLocalizedString(@"More",@"titleForHeaderInSection case 1");
        default:
            return nil;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.imageView.image = nil;
    
    switch( indexPath.row) {
        case 0:
            if (indexPath.section == 0) {
                cell.textLabel.text = NSLocalizedString(@"contact@onebusaway.org",@"cell.textLabel.text case 0");
            } else
            {
                cell.textLabel.text = NSLocalizedString(@"OneBusAway issue tracker",@"cell.textLabel.text case 1");
            }
            break;
        case 1:
            if (indexPath.section == 0) {
                cell.textLabel.text = NSLocalizedString(@"http://twitter.com/onebusaway",@"case 1");
            } else
            {
                cell.textLabel.text = NSLocalizedString(@"Privacy policy",@"cell.textLabel.text case 2");

            }
            break;
        case 2:

            break;

    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch( indexPath.row) {
        case 0:
            if (indexPath.section == 0) {
                NSString *url = [NSString stringWithString: NSLocalizedString(@"mailto:contact@onebusaway.org",@"didSelectRowAtIndexPath case 1")];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
            } else
            {
                NSString *url = [NSString stringWithString: NSLocalizedString(@"https://github.com/OneBusAway/onebusaway-iphone/issues",@"didSelectRowAtIndexPath case 2")];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
            }
            break;
        case 1:
            if (indexPath.section == 0) {
                NSString *url = [NSString stringWithString: NSLocalizedString(@"http://twitter.com/onebusaway",@"case 0")];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];            } else
            {
                NSString *url = [NSString stringWithString: NSLocalizedString(@"http://pugetsound.onebusaway.org/p/PrivacyPolicy.action",@"didSelectRowAtIndexPath case 3")];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
            }
            break;
        case 2:
        {

        }
            break;
            
    }
    

}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeContactUs];
}

@end


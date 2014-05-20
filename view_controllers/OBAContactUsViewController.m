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
#import "OBANavigationTargetAware.h"
#import <sys/utsname.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "OBAAnalytics.h"

#define kEmailRow 0
#define kTwitterRow 1
#define kFacebookRow 2

#define kRowCount 3 //including Facebook which is optional

static NSString *kOBADefaultContactEmail = @"contact@onebusaway.org";
static NSString *kOBADefaultTwitterURL = @"http://twitter.com/onebusaway";

@implementation OBAContactUsViewController


- (id)init {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.title = NSLocalizedString(@"Contact Us", @"Contact us tab title");
        self.appDelegate = APP_DELEGATE;
    }
    return self;
}

#pragma mark mail methods

- (void)mailComposeController:(MFMailComposeViewController*)controller  
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError*)error;
{
    [self becomeFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cantSendEmail
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Setup Mail",@"view.title")
                                                    message:NSLocalizedString(@"Please setup your Mail app before trying to send an email.",@"view.message")
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"Okay", @"Ok button"), nil];
    
    [alert show];
}

#pragma mark UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self hideEmptySeparators];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    [OBAAnalytics reportScreenView:[NSString stringWithFormat:@"View: %@", [self class]]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark Table view methods

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OBARegionV2 *region = _appDelegate.modelDao.region;
    if (region.facebookUrl && ![region.facebookUrl isEqualToString:@""]) {
        return kRowCount;
    }
    
    //if no facebook URL 1 less row
    return (kRowCount-1);
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.imageView.image = nil;

    cell.textLabel.font = [UIFont systemFontOfSize:18];
    
    switch( indexPath.row) {
        case kEmailRow:
            cell.textLabel.text = NSLocalizedString(@"Email", @"Email title");
            break;
        case kTwitterRow:
            cell.textLabel.text = NSLocalizedString(@"Twitter", @"Twitter title");
            break;
        case kFacebookRow:
            cell.textLabel.text = NSLocalizedString(@"Facebook", @"Facebook title");
            break;
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OBARegionV2 *region = _appDelegate.modelDao.region;
    switch( indexPath.row) {
        case kEmailRow:
            {
                [OBAAnalytics reportEventWithCategory:@"ui_action" action:@"button_press" label:@"Clicked Email Link" value:nil];

                //check if user can send email
                if ([MFMailComposeViewController canSendMail]){
                    // Create and show composer
                    NSString *contactEmail = kOBADefaultContactEmail;
                    if (region) {
                        contactEmail = region.contactEmail;
                    }

                    //device model, thanks to http://stackoverflow.com/a/11197770/1233435
                    struct utsname systemInfo;
                    uname(&systemInfo);
                    
                    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                    CLLocation * location = _appDelegate.locationManager.currentLocation;                

                    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
                    if (controller != nil){
                        controller.mailComposeDelegate=self;
                				[controller setToRecipients:[NSArray arrayWithObject:contactEmail]];
                				[controller setSubject:NSLocalizedString(@"OneBusAway iOS Feedback", @"feedback mail subject")];
                				[controller setMessageBody:[NSString stringWithFormat:@"<br><br>---------------<br>App Version: %@<br>Device: \
                            <a href='http://stackoverflow.com/a/11197770/1233435'>%@</a><br>iOS Version: %@<br>Current Location: %f, %f", 
                            appVersionString, [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding], 
                            [[UIDevice currentDevice] systemVersion], location.coordinate.latitude, location.coordinate.longitude] isHTML:YES]; 
                				
                        [self presentViewController:controller animated:YES completion:^{ }];
                    }else{
                        [self cantSendEmail];
                    }
                }else{
                    [self cantSendEmail];
                }
            }
            break;
        case kTwitterRow:
            {
                [OBAAnalytics reportEventWithCategory:@"ui_action" action:@"button_press" label:@"Clicked Twitter Link" value:nil];
                NSString *twitterUrl = kOBADefaultTwitterURL;
                if (region) {
                    twitterUrl = region.twitterUrl;
                }
                NSString *twitterName = [[twitterUrl componentsSeparatedByString:@"/"] lastObject];
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
                    [OBAAnalytics reportEventWithCategory:@"ui_action" action:@"app_switch" label:@"Loaded Twitter via App" value:nil];
                    NSString *url = [NSString stringWithFormat:@"twitter://user?screen_name=%@",twitterName ];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                } else {
                    [OBAAnalytics reportEventWithCategory:@"ui_action" action:@"app_switch" label:@"Loaded Twitter via Web" value:nil];
                    NSString *url = [NSString stringWithFormat:@"http://twitter.com/%@", twitterName];
                    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
                }
            }
            break;
        case kFacebookRow:
            if (region.facebookUrl) {
                [OBAAnalytics reportEventWithCategory:@"ui_action" action:@"button_press" label:@"Clicked Facebook Link" value:nil];
                NSString *facebookUrl = region.facebookUrl;
                NSString *facebookPage = [[facebookUrl componentsSeparatedByString:@"/"] lastObject];

                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]]) {
                    [OBAAnalytics reportEventWithCategory:@"ui_action" action:@"app_switch" label:@"Loaded Facebook via App" value:nil];
                    NSString *url = [NSString stringWithFormat:@"fb://profile/%@",facebookPage ];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
                } else {
                    [OBAAnalytics reportEventWithCategory:@"ui_action" action:@"app_switch" label:@"Loaded Facebook via Web" value:nil];
                    NSString *url = [NSString stringWithFormat:@"http://facebook.com/%@", facebookPage];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
                }
            }
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{        
    return 0.0;
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeContactUs];
}

@end

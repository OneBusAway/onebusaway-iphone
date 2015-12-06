//
//  OBACustomApiViewController.m
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 12.08.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBACustomApiViewController.h"
#import "OBAApplicationDelegate.h"
#import "OBATextFieldTableViewCell.h"
#import "UITableViewController+oba_Additions.h"
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "OBAURLHelpers.h"

typedef NS_ENUM (NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeEditing,
    OBASectionTypeRecent,
};

@interface OBACustomApiViewController ()
@property (nonatomic,strong) OBAApplicationDelegate *appDelegate;
@property (nonatomic,strong) OBAModelDAO *modelDao;
@property (nonatomic) NSArray *recentUrls;
@property (nonatomic) UITextField *customApiUrlTextField;
@end

@implementation OBACustomApiViewController

- (instancetype)initWithApplicationDelegate:(OBAApplicationDelegate *)appDelegate modelDao:(OBAModelDAO *)modelDao {
    self = [super initWithStyle:UITableViewStylePlain];

    if (self) {
        _appDelegate = appDelegate;
        _modelDao = modelDao;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel button title") style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save button title") style:UIBarButtonItemStyleDone target:self action:@selector(save)];

    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"Custom API URL", @"title");
    self.recentUrls = self.modelDao.mostRecentCustomApiUrls;
    [self hideEmptySeparators];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.customApiUrlTextField becomeFirstResponder];
}

#pragma mark - Actions

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save {
    [SVProgressHUD show];
    [self saveCustomApiUrl:self.customApiUrlTextField.text];
}

- (void)showBadURLError:(NSString*)message {
    [SVProgressHUD dismiss];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Server Address Invalid", @"Bad custom API URL alert title.") message:message ?: NSLocalizedString(@"Please check the URL and try again.", @"A generic error message for the server address invalid message.") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"Default alert dismissal button title") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Model Data

- (void)saveCustomApiUrl:(NSString*)urlString {

    urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (urlString.length == 0) {
        [self showBadURLError:nil];
        return;
    }

    if ([urlString isEqualToString:self.modelDao.readCustomApiUrl]) {
        [self showBadURLError:NSLocalizedString(@"It's not necessarily invalid. You just didn't type in a new address.", @"Identical server address to what we already have.")];
        return;
    }

    NSURL *currentTimeURL = [OBAURLHelpers normalizeURLPath:@"/where/current-time.json"
                                          relativeToBaseURL:urlString
                                                 parameters:@{@"key": @"org.onebusaway.iphone"}];

    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithURL:currentTimeURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        if (error) {
            [SVProgressHUD showErrorWithStatus:error.userInfo[NSLocalizedDescriptionKey]];
            return;
        }

        if (!data) {
            [self showBadURLError:nil];
            return;
        }

        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:NULL];

        if (!jsonObject) {
            [self showBadURLError:nil];
            return;
        }

        if (jsonObject[@"currentTime"]) {
            // hooray it actually worked!
            [SVProgressHUD dismiss];
            [self writeCustomAPIURLString:urlString];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [task resume];
}

- (void)writeCustomAPIURLString:(NSString*)urlString {
    [self.modelDao addCustomApiUrl:urlString];
    [self.modelDao writeCustomApiUrl:urlString];
    [self.modelDao writeSetRegionAutomatically:NO];
    [self.modelDao setOBARegion:nil];

    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.appDelegate regionSelected];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeEditing:
            return 1;

        case OBASectionTypeRecent:
            return [self.recentUrls count];

        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeEditing:
            return [self editingCellForRowAtIndexPath:indexPath tableView:tableView];

        case OBASectionTypeRecent:
            return [self recentCellForRowAtIndexPath:indexPath tableView:tableView];

        default:
            break;
    }

    return [UITableViewCell getOrCreateCellForTableView:tableView];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeRecent: {
            NSString *urlString = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
            [self saveCustomApiUrl:urlString];
            break;
        }

        default:
            break;
    }
}

- (OBASectionType)sectionTypeForSection:(NSUInteger)section {
    if (section == 0) {
        return OBASectionTypeEditing;
    }
    else if (section == 1) {
        return OBASectionTypeRecent;
    }

    return OBASectionTypeNone;
}

- (UITableViewCell *)editingCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBATextFieldTableViewCell *cell =  [OBATextFieldTableViewCell getOrCreateCellForTableView:tableView];

    cell.textField.placeholder = @"http://example.onebusaway.org/api/";
    cell.textField.text = [OBAApplication sharedApplication].modelDao.readCustomApiUrl;
    cell.textField.delegate = self;
    cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    cell.textField.returnKeyType = UIReturnKeyDone;
    cell.textField.font = [UIFont systemFontOfSize:18];
    self.customApiUrlTextField = cell.textField;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (UITableViewCell *)recentCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.text = [self.recentUrls objectAtIndex:indexPath.row];
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)localTextField {
    [localTextField resignFirstResponder];
    [self save];
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch ([self sectionTypeForSection:section]) {
        case OBASectionTypeEditing:
        case OBASectionTypeRecent:
            return 40;

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
    switch ([self sectionTypeForSection:section]) {
        case OBASectionTypeEditing:
            title.text = NSLocalizedString(@"Edit", @"custom url edit");
            break;

        case OBASectionTypeRecent:
            title.text = NSLocalizedString(@"Recent", @"custom url recent");
            break;

        default:
            break;
    }
    [view addSubview:title];
    return view;
}

@end

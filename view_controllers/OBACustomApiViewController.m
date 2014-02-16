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

typedef enum {
	OBASectionTypeNone,
    OBASectionTypeEditing,
    OBASectionTypeRecent,
} OBASectionType;

static NSString *editingCellTag = @"editingCell";

@interface OBACustomApiViewController ()
@property (nonatomic) OBAApplicationDelegate *appDelegate;
@property (nonatomic) NSArray *recentUrls;
@property (nonatomic) UITextField *customApiUrlTextField;

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;
- (UITableViewCell*) editingCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) recentCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (void) saveCustomApiUrl;
@end

@implementation OBACustomApiViewController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.appDelegate = appDelegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"Custom API URL", @"title");
    self.recentUrls = self.appDelegate.modelDao.mostRecentCustomApiUrls;
    [self hideEmptySeparators];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self saveCustomApiUrl];
    [super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
        case OBASectionTypeRecent:
            self.customApiUrlTextField.text = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
            [self saveCustomApiUrl];
		default:
			break;
	}
}

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	
    if (section == 0) {
        return OBASectionTypeEditing;
    } else if (section == 1){
        return OBASectionTypeRecent;
    }
	
	return OBASectionTypeNone;
}

- (UITableViewCell*) editingCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    
    OBATextFieldTableViewCell * cell =  [OBATextFieldTableViewCell getOrCreateCellForTableView:tableView];
    //cell.textField.text = _bookmark.name;
    //_textField = cell.textField;
    //[_textField becomeFirstResponder];
    //[tableView addSubview:cell]; // make keyboard slide in/out from right.
    cell.textField.placeholder = @"example.onebusaway.org/api/";
    cell.textField.text = self.appDelegate.modelDao.readCustomApiUrl;
    cell.textField.tag = editingCellTag;
    cell.textField.delegate = self;
    cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    cell.textField.returnKeyType = UIReturnKeyDone;
    cell.textField.font = [UIFont systemFontOfSize:18];
    self.customApiUrlTextField = cell.textField;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (UITableViewCell*) recentCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.text = [self.recentUrls objectAtIndex:indexPath.row];
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)localTextField {
    [self saveCustomApiUrl];
    [localTextField resignFirstResponder];
    return YES;
}

- (void) saveCustomApiUrl {
    if (![self.customApiUrlTextField.text isEqualToString:self.appDelegate.modelDao.readCustomApiUrl]) {


        if (![self.customApiUrlTextField.text isEqualToString:@""]) {
            [self.appDelegate.modelDao addCustomApiUrl:self.customApiUrlTextField.text];
            [self.appDelegate.modelDao writeCustomApiUrl:self.customApiUrlTextField.text];
            [self.appDelegate.modelDao writeSetRegionAutomatically:NO];
            [self.appDelegate.modelDao setOBARegion:nil];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.appDelegate regionSelected];
        }

    }
    [self.tableView reloadData];

}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	switch ([self sectionTypeForSection:section]) {
        case OBASectionTypeEditing:
        case OBASectionTypeRecent:
            return 40;
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

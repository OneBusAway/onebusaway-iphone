//
//  OBASubmitReportViewController.m
//  org.onebusaway.iphone
//
//  Created by Vania Kurniawati on 3/21/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBASubmitReportViewController.h"
//#import "OBAReport.h"

@interface OBASubmitReportViewController ()
@property (weak, nonatomic) IBOutlet UILabel *busInfoLabel;
- (IBAction)busFullSwitch:(id)sender;

@end

@implementation OBASubmitReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
  self.busInfoLabel.text = @"Hello, user!"; //replace with bus information from previous screen
  
  
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)busFullSwitch:(id)sender {
  
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thanks!" message:@"Your input has been submitted. Your fellow bus riders thank you!" delegate:self cancelButtonTitle:@"Yay!" otherButtonTitles:nil, nil];
  
  [alert show];
}
@end

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
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)busFullSwitch:(id)sender {
  
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thanks!" message:@"Your input has been submitted. Your fellow bus riders thank you!" delegate:self cancelButtonTitle:@"Yay!" otherButtonTitles:nil, nil];
  
  [alert show];
}
@end

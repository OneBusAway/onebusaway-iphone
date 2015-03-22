//
//  OBASubmitReportViewController.m
//  org.onebusaway.iphone
//
//  Created by Vania Kurniawati on 3/21/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBASubmitReportViewController.h"
#import "OBACommonV1.h"
#import "OBAProblemReport.h"
#import "OBAGenericStopViewController.h"

@interface OBASubmitReportViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@end

@implementation OBASubmitReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  self.submitButton.backgroundColor = OBADARKGREEN;
  self.navigationController.title = @"Submit Report";
  
  [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16.f],
                                                 NSForegroundColorAttributeName: [UIColor blackColor]}
                                       forState: UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)submitButtonPress:(id)sender {
  OBAProblemReport *problemReport = [OBAProblemReport object];
  problemReport.tripID = _selectedArrivalAndDeparture.tripId;
  problemReport.problemReportType = _segmentedControl.selectedSegmentIndex;
  problemReport.comments = _commentTextField.text;
  
  if (_selectedArrivalAndDeparture.stop) {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:_selectedArrivalAndDeparture.stop.lat longitude:_selectedArrivalAndDeparture.stop.lon];
    problemReport.location = [PFGeoPoint geoPointWithLocation:location];
  }
  
  [problemReport saveInBackground];
  [self createAlertViewForReportSubmissionNotification];
  
  NSArray *viewControllers = [[self navigationController] viewControllers];
  for( int i=0;i<[viewControllers count];i++){
    id obj=[viewControllers objectAtIndex:i];
    if([obj isKindOfClass:[OBAGenericStopViewController class]]){
      [[self navigationController] popToViewController:obj animated:YES];
      return;
    }
  }
}

-(void)createAlertViewForReportSubmissionNotification {
  NSString *alertMessage = NSLocalizedString(@"Thanks for submitting your report", @"");
  
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"+10 points", @"")
                                                      message:alertMessage
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"OK", @"Cancel button label")
                                            otherButtonTitles:nil, nil];
  [alertView show];
}

@end
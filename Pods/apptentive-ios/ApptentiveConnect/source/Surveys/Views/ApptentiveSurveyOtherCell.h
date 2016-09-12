//
//  ApptentiveSurveyOtherCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/4/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyChoiceCell.h"


@interface ApptentiveSurveyOtherCell : ApptentiveSurveyChoiceCell

@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (assign, nonatomic, getter=isValid) BOOL valid;
@property (strong, nonatomic) UIColor *validColor;
@property (strong, nonatomic) UIColor *invalidColor;

@end

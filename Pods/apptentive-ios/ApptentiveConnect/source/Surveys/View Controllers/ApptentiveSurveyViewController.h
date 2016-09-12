//
//  ApptentiveSurveyViewController.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/22/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveSurveyCollectionView.h"
#import "ApptentiveSurveyViewModel.h"


@interface ApptentiveSurveyViewController : UICollectionViewController <UICollectionViewDelegateFlowLayout, UITextViewDelegate, UITextFieldDelegate, ApptentiveCollectionViewDataSource, ATSurveyViewModelDelegate>

@property (strong, nonatomic) ApptentiveSurveyViewModel *viewModel;

@end

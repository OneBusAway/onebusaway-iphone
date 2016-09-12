//
//  ApptentiveSurveyLayoutAttributes.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ApptentiveSurveyLayoutAttributes : UICollectionViewLayoutAttributes

@property (assign, nonatomic, getter=isValid) BOOL valid;
@property (strong, nonatomic) UIColor *validColor;
@property (strong, nonatomic) UIColor *invalidColor;
@property (strong, nonatomic) UIColor *backgroundColor;

@end

//
//  ApptentiveMessageCenterViewController.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveMessageCenterDataSource.h"
#import "ApptentiveBackend.h"

@class ApptentiveMessageCenterInteraction;


@interface ApptentiveMessageCenterViewController : UITableViewController <ApptentiveMessageCenterDataSourceDelegate, UITextViewDelegate, UITextFieldDelegate, ATBackendMessageDelegate, UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) ApptentiveMessageCenterInteraction *interaction;

@end

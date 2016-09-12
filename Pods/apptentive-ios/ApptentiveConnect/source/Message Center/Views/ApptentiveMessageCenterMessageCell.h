//
//  ApptentiveMessageCenterMessageCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveMessageCenterCellProtocols.h"


@interface ApptentiveMessageCenterMessageCell : UITableViewCell <ApptentiveMessageCenterCell>

@property (weak, nonatomic) IBOutlet UITextView *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (assign, nonatomic) BOOL statusLabelHidden;

@end

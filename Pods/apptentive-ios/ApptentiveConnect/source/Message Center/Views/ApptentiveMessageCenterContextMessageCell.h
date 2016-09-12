//
//  ApptentiveMessageCenterContextMessageCell.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 7/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveMessageCenterCellProtocols.h"


@interface ApptentiveMessageCenterContextMessageCell : UITableViewCell <ApptentiveMessageCenterCell>

@property (weak, nonatomic) IBOutlet UITextView *messageLabel;

@end

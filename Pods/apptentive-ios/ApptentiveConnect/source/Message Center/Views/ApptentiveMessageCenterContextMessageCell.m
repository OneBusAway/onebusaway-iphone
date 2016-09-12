//
//  ApptentiveMessageCenterContextMessageCell.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 7/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterContextMessageCell.h"


@implementation ApptentiveMessageCenterContextMessageCell

- (void)awakeFromNib {
	self.messageLabel.textContainerInset = UIEdgeInsetsZero;
	self.messageLabel.textContainer.lineFragmentPadding = 0;

	[super awakeFromNib];
}

@end

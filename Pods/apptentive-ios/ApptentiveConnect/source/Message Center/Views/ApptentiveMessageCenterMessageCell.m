//
//  ApptentiveMessageCenterMessageCell.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterMessageCell.h"


@implementation ApptentiveMessageCenterMessageCell

- (void)awakeFromNib {
	self.messageLabel.textContainerInset = UIEdgeInsetsZero;
	self.messageLabel.textContainer.lineFragmentPadding = 0;

	[super awakeFromNib];
}


- (void)setStatusLabelHidden:(BOOL)statusLabelHidden {
	_statusLabelHidden = statusLabelHidden;

	self.statusLabel.hidden = statusLabelHidden;
}

@end

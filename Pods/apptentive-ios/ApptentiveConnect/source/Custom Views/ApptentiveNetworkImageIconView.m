//
//  ApptentiveNetworkImageIconView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 6/1/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveNetworkImageIconView.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveBackend.h"


@implementation ApptentiveNetworkImageIconView

- (void)setImageURL:(NSURL *)imageURL {
	if (imageURL == nil) {
		self.maskType = ATImageViewMaskTypeAppIcon;
		self.image = [ApptentiveUtilities appIcon];
	} else {
		self.maskType = ATImageViewMaskTypeRound;
		self.image = nil;
	}

	[super setImageURL:imageURL];
}

- (void)setMaskType:(ATImageViewMaskType)maskType {
	_maskType = maskType;

	[self updateImageMask];
}

- (void)updateImageMask {
	switch (self.maskType) {
		case ATImageViewMaskTypeNone:
			self.layer.cornerRadius = 0.0;
			self.layer.mask = nil;
			break;

		case ATImageViewMaskTypeRound:
			self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2.0;
			self.layer.mask = nil;
			break;

		case ATImageViewMaskTypeAppIcon: {
			CALayer *maskLayer = [CALayer layer];
			maskLayer.contents = (id)[ApptentiveBackend imageNamed:@"at_update_icon_mask"].CGImage;
			maskLayer.frame = self.bounds;

			self.layer.cornerRadius = 0.0;
			self.layer.mask = maskLayer;
			break;
		}
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];

	[self updateImageMask];
}

@end

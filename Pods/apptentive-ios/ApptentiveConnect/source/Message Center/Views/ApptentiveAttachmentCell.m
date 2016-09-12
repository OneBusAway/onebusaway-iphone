//
//  ApptentiveAttachmentCell.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 10/23/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAttachmentCell.h"
#import "ApptentiveBackend.h"

#define PLACEHOLDER_SIZE CGSizeMake(37, 48)


@interface ApptentiveAttachmentCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeight;

@end


@implementation ApptentiveAttachmentCell

+ (CGSize)portraitSizeOfScreen:(UIScreen *)screen {
	CGFloat width = CGRectGetWidth(screen.bounds);
	CGFloat height = CGRectGetHeight(screen.bounds);

	if (width > height) {
		CGFloat newWidth = height;
		height = width;
		width = newWidth;
	}

	return CGSizeMake(width, height);
}

+ (NSInteger)countForScreen:(UIScreen *)screen {
	return [self portraitSizeOfScreen:screen].width > 400.0 ? 5 : 4;
}

+ (CGSize)sizeForScreen:(UIScreen *)screen withMargin:(CGSize)margin {
	CGSize size = [self portraitSizeOfScreen:screen];
	CGFloat aspectRatio = size.width / size.height;
	NSInteger count = [self countForScreen:screen];
	CGFloat totalMargin = margin.width * (count + 1);
	CGFloat imageWidth = (size.width - totalMargin) / count;
	CGFloat imageHeight = imageWidth / aspectRatio;

	return CGSizeMake(floor(imageWidth * 2.0) / 2.0, floor(imageHeight * 2.0) / 2.0);
}

+ (CGFloat)heightForScreen:(UIScreen *)screen withMargin:(CGSize)margin {
	CGSize itemSize = [self sizeForScreen:screen withMargin:margin];

	return round(itemSize.height + margin.height * 2.0);
}

- (void)setUsePlaceholder:(BOOL)usePlaceholder {
	_usePlaceholder = usePlaceholder;
	CGSize imageSize = usePlaceholder ? PLACEHOLDER_SIZE : self.bounds.size;

	self.imageWidth.constant = imageSize.width;
	self.imageHeight.constant = imageSize.height;

	self.imageView.contentMode = usePlaceholder ? UIViewContentModeScaleToFill : UIViewContentModeScaleAspectFit;
	self.extensionLabel.hidden = !usePlaceholder;
	self.imageView.backgroundColor = usePlaceholder ? [UIColor clearColor] : [UIColor lightGrayColor];

	if (usePlaceholder) {
		self.layer.borderWidth = 1.0;
		self.layer.cornerRadius = 5.0;
	} else {
		self.layer.borderWidth = 0;
		self.layer.cornerRadius = 0;
	}
}

- (void)awakeFromNib {
	self.layer.borderColor = [UIColor colorWithWhite:0.7 alpha:1.0].CGColor;
	self.translatesAutoresizingMaskIntoConstraints = NO;
	self.imageView.translatesAutoresizingMaskIntoConstraints = NO;

	self.extensionLabel.textColor = self.tintColor;
	self.usePlaceholder = YES;

	self.deleteButton.imageEdgeInsets = UIEdgeInsetsMake(0, 22.0, 22.0, 0);
	[self.deleteButton setImage:[ApptentiveBackend imageNamed:@"at_remove"] forState:UIControlStateNormal];
	self.deleteButton.imageView.backgroundColor = [UIColor redColor];
	self.deleteButton.imageView.tintColor = [UIColor whiteColor];
	self.deleteButton.imageView.layer.cornerRadius = CGRectGetWidth(self.deleteButton.imageView.bounds) / 2.0;

	[super awakeFromNib];
}

@end

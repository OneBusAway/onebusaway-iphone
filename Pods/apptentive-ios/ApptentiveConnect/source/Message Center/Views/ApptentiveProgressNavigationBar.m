//
//  ApptentiveProgressNavigationBar.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/29/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveProgressNavigationBar.h"


@implementation ApptentiveProgressNavigationBar

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self addProgressView];
	}
	return self;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		[self addProgressView];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self addProgressView];
	}
	return self;
}

- (void)addProgressView {
	_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
	[self addSubview:self.progressView];
	CGFloat height = CGRectGetHeight(self.bounds);

	self.progressView.frame = CGRectMake(0.0, height - CGRectGetHeight(self.progressView.bounds), CGRectGetWidth(self.bounds), CGRectGetHeight(self.progressView.bounds));
	self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
}

@end

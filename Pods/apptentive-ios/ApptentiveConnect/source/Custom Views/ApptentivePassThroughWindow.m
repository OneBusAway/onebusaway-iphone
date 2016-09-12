//
//  ApptentivePassThroughWindow.m
//  ATHUD
//
//  Created by Frank Schmitt on 3/2/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePassThroughWindow.h"


@implementation ApptentivePassThroughWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	id hitView = [super hitTest:point withEvent:event];

	// Ignore clicks in window or its root view
	if (hitView == self || hitView == self.subviews.firstObject) {
		return nil;
	} else {
		return hitView;
	}
}

@end

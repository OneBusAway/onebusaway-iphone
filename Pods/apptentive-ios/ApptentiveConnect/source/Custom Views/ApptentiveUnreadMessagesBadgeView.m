//
//  ApptentiveUnreadMessagesBadgeView.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 6/19/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveUnreadMessagesBadgeView.h"
#import "Apptentive.h"


@interface ApptentiveUnreadMessagesBadgeView ()

@property (strong, nonatomic) UILabel *label;

@end


@implementation ApptentiveUnreadMessagesBadgeView

+ (instancetype)unreadMessageCountViewBadgeWithApptentiveHeart {
	ApptentiveUnreadMessagesBadgeView *badge = [[self alloc] initWithFrame:CGRectMake(0, 0, 32.0, 32.0)];

	UILabel *label = [self unreadMessageCountLabel];
	label.textColor = [UIColor blackColor];
	[label setCenter:CGPointMake(badge.frame.size.width / 2, badge.frame.size.height / 2)];
	badge.label = label;
	[badge addSubview:label];

	CAShapeLayer *heart = [[CAShapeLayer alloc] init];
	[heart setPath:[self heartBezierPath].CGPath];
	heart.fillColor = [[UIColor colorWithRed:237.0 / 255.0 green:31.0 / 255.0 blue:51.0 / 255.0 alpha:1] CGColor];

	CGRect heartFrame = heart.frame;
	heartFrame.origin.x = CGRectGetMaxX(badge.label.frame);
	heartFrame.origin.y = CGRectGetMinY(badge.label.frame) - 3;
	heart.frame = heartFrame;
	[[badge layer] addSublayer:heart];

	return badge;
}

+ (instancetype)unreadMessageCountViewBadge {
	CGFloat diameter = 28.0;

	ApptentiveUnreadMessagesBadgeView *badge = [[self alloc] initWithFrame:CGRectMake(0, 0, diameter, diameter)];
	badge.backgroundColor = [UIColor colorWithRed:237.0 / 255.0 green:31.0 / 255.0 blue:51.0 / 255.0 alpha:1];
	badge.layer.cornerRadius = diameter / 2;
	badge.layer.masksToBounds = YES;

	UILabel *label = [self unreadMessageCountLabel];
	label.textColor = [UIColor whiteColor];
	[label setCenter:CGPointMake(badge.frame.size.width / 2, badge.frame.size.height / 2)];
	badge.label = label;
	[badge addSubview:label];

	return badge;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadMessageCountChanged:) name:ApptentiveMessageCenterUnreadCountChangedNotification object:nil];
	}

	return self;
}

+ (UILabel *)unreadMessageCountLabel {
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 32.0, 32.0)];
	[label setText:[NSString stringWithFormat:@"%lu", (unsigned long)[[Apptentive sharedConnection] unreadMessageCount]]];
	[label setBackgroundColor:[UIColor clearColor]];
	[label setFont:[UIFont systemFontOfSize:16.0f]];
	[label sizeToFit];

	return label;
}

- (void)unreadMessageCountChanged:(NSNotification *)notification {
	NSNumber *unreadMessageCount = notification.userInfo[@"count"] ?: @0;
	self.label.text = [NSString stringWithFormat:@"%@", unreadMessageCount];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (UIBezierPath *)heartBezierPath {
	UIBezierPath *heart = UIBezierPath.bezierPath;
	[heart moveToPoint:CGPointMake(7.88, 6.95)];
	[heart addLineToPoint:CGPointMake(1.7, 8.98)];
	[heart addLineToPoint:CGPointMake(0.06, 3.25)];
	[heart addCurveToPoint:CGPointMake(0.42, 1.46) controlPoint1:CGPointMake(-0.08, 2.64) controlPoint2:CGPointMake(0.02, 2.06)];
	[heart addCurveToPoint:CGPointMake(2.13, 0.17) controlPoint1:CGPointMake(0.77, 0.79) controlPoint2:CGPointMake(1.32, 0.38)];
	[heart addCurveToPoint:CGPointMake(4.2, 0.23) controlPoint1:CGPointMake(2.82, -0.05) controlPoint2:CGPointMake(3.54, -0.08)];
	[heart addCurveToPoint:CGPointMake(5.52, 1.55) controlPoint1:CGPointMake(4.81, 0.47) controlPoint2:CGPointMake(5.27, 0.93)];
	[heart addCurveToPoint:CGPointMake(4.45, 5.39) controlPoint1:CGPointMake(6.26, 3.52) controlPoint2:CGPointMake(5.92, 4.78)];
	[heart addCurveToPoint:CGPointMake(4.48, 2.44) controlPoint1:CGPointMake(4.77, 4.24) controlPoint2:CGPointMake(4.81, 3.3)];
	[heart addCurveToPoint:CGPointMake(2.54, 1.57) controlPoint1:CGPointMake(4.15, 1.58) controlPoint2:CGPointMake(3.49, 1.27)];
	[heart addCurveToPoint:CGPointMake(1.4, 3.04) controlPoint1:CGPointMake(1.67, 1.83) controlPoint2:CGPointMake(1.29, 2.32)];
	[heart addLineToPoint:CGPointMake(2.6, 7.19)];
	[heart addLineToPoint:CGPointMake(7.32, 5.65)];
	[heart addCurveToPoint:CGPointMake(8.18, 4.8) controlPoint1:CGPointMake(7.71, 5.46) controlPoint2:CGPointMake(8.05, 5.2)];
	[heart addCurveToPoint:CGPointMake(8.3, 3.4) controlPoint1:CGPointMake(8.38, 4.35) controlPoint2:CGPointMake(8.46, 3.89)];
	[heart addCurveToPoint:CGPointMake(7.48, 2.3) controlPoint1:CGPointMake(8.15, 2.91) controlPoint2:CGPointMake(7.92, 2.47)];
	[heart addCurveToPoint:CGPointMake(6.49, 2.13) controlPoint1:CGPointMake(7.1, 2.08) controlPoint2:CGPointMake(6.86, 2.06)];
	[heart addLineToPoint:CGPointMake(6.08, 0.73)];
	[heart addCurveToPoint:CGPointMake(8.34, 1.04) controlPoint1:CGPointMake(6.88, 0.52) controlPoint2:CGPointMake(7.59, 0.6)];
	[heart addCurveToPoint:CGPointMake(9.82, 2.86) controlPoint1:CGPointMake(9.05, 1.42) controlPoint2:CGPointMake(9.54, 2.06)];
	[heart addCurveToPoint:CGPointMake(9.52, 5.3) controlPoint1:CGPointMake(10.05, 3.59) controlPoint2:CGPointMake(9.91, 4.4)];
	[heart addCurveToPoint:CGPointMake(7.88, 6.95) controlPoint1:CGPointMake(9.02, 6.19) controlPoint2:CGPointMake(8.45, 6.72)];
	[heart addLineToPoint:CGPointMake(7.88, 6.95)];
	[heart closePath];

	heart.miterLimit = 4;
	heart.usesEvenOddFillRule = YES;

	return heart;
}

@end

//
//  OBAUIBuilder.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/12/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBAUIBuilder : NSObject
+ (UILabel*)label;
+ (UIView*)footerViewWithText:(NSString*)text maximumWidth:(CGFloat)width;
+ (UIView*)lineView;

@end

NS_ASSUME_NONNULL_END

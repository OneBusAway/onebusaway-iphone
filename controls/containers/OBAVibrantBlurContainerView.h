//
//  OBAVibrantBlurContainerView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBAVibrantBlurContainerView : UIView
@property(nonatomic,assign) UIBlurEffectStyle blurEffectStyle;
@property(nonatomic,strong,readonly) UIVisualEffectView *vibrancyEffectView;
@end

//
//  OBANavigationTitleView.h
//  org.onebusaway.iphone
//
//  Created by Cathy Oun on 5/13/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MarqueeLabel;

typedef NS_ENUM(NSInteger, OBAAppearanceNavBarTitleViewStyle){
    OBAAppearanceNavBarTitleViewStyleDefault, // subtitle won't be displayed
    OBAAppearanceNavBarTitleViewStyleSubtitle,
};

@interface OBANavigationTitleView : UIView

@property(nonatomic,strong,readonly) MarqueeLabel *titleLabel;
@property(nonatomic,strong,readonly) MarqueeLabel *subtitleLabel;

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                        style:(OBAAppearanceNavBarTitleViewStyle)style;


@end

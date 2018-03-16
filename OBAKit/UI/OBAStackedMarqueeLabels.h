//
//  OBAStackedMarqueeLabels.h
//  OBAKit
//
//  Created by Aaron Brethorst on 1/6/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import UIKit;
@import MarqueeLabel;

@interface OBAStackedMarqueeLabels : UIView
@property(nonatomic,strong,readonly) MarqueeLabel *topLabel;
@property(nonatomic,strong,readonly) MarqueeLabel *bottomLabel;

- (instancetype)initWithWidth:(CGFloat)width;
@end

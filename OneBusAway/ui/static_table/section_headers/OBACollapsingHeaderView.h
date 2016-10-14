//
//  OBACollapsingHeaderView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBACollapsingHeaderView : UIView
@property(nonatomic,copy) NSString *title;
@property(nonatomic,assign) BOOL isOpen;
@property (nonatomic,copy,nullable) void (^tapped)(BOOL isOpen);
@end

NS_ASSUME_NONNULL_END

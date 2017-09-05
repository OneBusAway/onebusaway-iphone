//
//  OBAClassicDepartureView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;

@class OBADepartureRow;

NS_ASSUME_NONNULL_BEGIN

@interface OBAClassicDepartureView : UIView
@property(nonatomic,copy) OBADepartureRow *departureRow;
@property(nonatomic,strong,readonly) UIButton *contextMenuButton;

- (void)prepareForReuse;
@end

NS_ASSUME_NONNULL_END

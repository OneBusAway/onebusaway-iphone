//
//  OBAClassicDepartureView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBADepartureRow.h>

NS_ASSUME_NONNULL_BEGIN

@class OBAOccupancyStatusView;

@interface OBAClassicDepartureView : UIView
@property(nonatomic,copy) OBADepartureRow *departureRow;
@property(nonatomic,strong,readonly) UIButton *contextMenuButton;
@property(nonatomic,strong,readonly) OBAOccupancyStatusView *occupancyStatusView;

- (void)prepareForReuse;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END

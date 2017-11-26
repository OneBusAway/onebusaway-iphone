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

typedef NS_ENUM(NSUInteger, OBAClassicDepartureViewLabelAlignment) {
    OBAClassicDepartureViewLabelAlignmentTop,
    OBAClassicDepartureViewLabelAlignmentCenter,
};

@interface OBAClassicDepartureView : UIView
@property(nonatomic,copy) OBADepartureRow *departureRow;
@property(nonatomic,strong,readonly) UIButton *contextMenuButton;
@property(nonatomic,assign,readonly) OBAClassicDepartureViewLabelAlignment labelAlignment;

- (instancetype)initWithLabelAlignment:(OBAClassicDepartureViewLabelAlignment)labelAlignment;

- (void)prepareForReuse;
@end

NS_ASSUME_NONNULL_END

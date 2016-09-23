//
//  OBAClassicDepartureView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OBADepartureRow;

NS_ASSUME_NONNULL_BEGIN

@interface OBAClassicDepartureView : UIView
@property(nonatomic,copy) OBADepartureRow *departureRow;

- (void)prepareForReuse;
@end

NS_ASSUME_NONNULL_END

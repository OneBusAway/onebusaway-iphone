//
//  OBAClassicDepartureView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OBAClassicDepartureRow;

NS_ASSUME_NONNULL_BEGIN

@interface OBAClassicDepartureView : UIView
@property(nonatomic,copy) OBAClassicDepartureRow *classicDepartureRow;

- (void)prepareForReuse;
@end

NS_ASSUME_NONNULL_END
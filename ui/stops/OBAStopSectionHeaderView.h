//
//  OBAStopSectionHeaderView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBAStopSectionHeaderView : UIView
@property(nonatomic,copy) NSString *routeNameText;
@property(nonatomic,copy) void (^favoriteButtonTapped)(BOOL selected);
@end

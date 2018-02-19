//
//  OBABookmarkedRouteCell.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABaseTableCell.h>
#import <OBAKit/OBAClassicDepartureView.h>

@interface OBABookmarkedRouteCell : OBABaseTableCell
@property(nonatomic,strong,readonly) OBAClassicDepartureView *departureView;
@end

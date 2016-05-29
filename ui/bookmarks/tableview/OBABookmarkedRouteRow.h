//
//  OBABookmarkedRouteRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"

@class OBABookmarkV2;
@class OBAArrivalAndDepartureV2;

@interface OBABookmarkedRouteRow : OBABaseRow
@property(nonatomic,copy) OBABookmarkV2 *bookmark;
@property(nonatomic,strong) OBAArrivalAndDepartureV2 *nextDeparture;
@end

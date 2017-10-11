//
//  OBAArrivalDepartureRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import OBAKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalDepartureRow : OBATableRow
@property(nonatomic,assign) BOOL selectedStopForRider;
@property(nonatomic,assign) BOOL closestStopToVehicle;
@property(nonatomic,assign) OBARouteType routeType;
@end

NS_ASSUME_NONNULL_END

//
//  OBARouteType.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/15/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#ifndef OBARouteType_h
#define OBARouteType_h

typedef NS_ENUM(NSUInteger, OBARouteType) {
    OBARouteTypeLightRail = 0,
    OBARouteTypeMetro = 1,
    OBARouteTypeTrain = 2,
    OBARouteTypeBus = 3,
    OBARouteTypeFerry = 4,
    OBARouteTypeUnknown = 999
};

#endif /* OBARouteType_h */

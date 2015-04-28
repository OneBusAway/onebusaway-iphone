//
//  OBARouteWK.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAModelObjectWK.h"

@interface OBARouteWK : OBAModelObjectWK

@property (nonatomic, copy) NSString *routeId;
@property (nonatomic, copy) id shortName;
@property (nonatomic, copy) id longName;
@property (nonatomic, copy) NSNumber *routeType;

@property (readonly) NSString *name;

@end

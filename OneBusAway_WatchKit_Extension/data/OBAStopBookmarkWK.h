//
//  OBAStopBookmarkWK.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/24/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAModelObjectWK.h"

@class OBAStopWK;

@interface OBAStopBookmarkWK : OBAModelObjectWK

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *stopId;
@property (nonatomic, copy) NSArray *routeFilter;    // NSString list of routeIds

@property (nonatomic, copy) NSString *stopInfoURLString;
@property (nonatomic, copy) NSString *arrivalsAndDeparturesURLString;

@end

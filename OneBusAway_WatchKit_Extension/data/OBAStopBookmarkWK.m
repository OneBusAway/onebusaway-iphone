//
//  OBAStopBookmarkWK.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/24/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAStopBookmarkWK.h"

@implementation OBAStopBookmarkWK

- (NSArray *)dictionaryRepresentationKeys {
    return @[@"name",
             @"stopId",
             @"routeFilter",
             @"stopInfoURLString",
             @"arrivalsAndDeparturesURLString"];
}

@end

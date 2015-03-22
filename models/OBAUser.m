//
//  OBAUser.m
//  org.onebusaway.iphone
//
//  Created by Pho Diep on 3/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAUser.h"

@implementation OBAUser

-(void)addUserPoints:(NSNumber*)pointsToAdd {
    self.points = [NSNumber numberWithFloat:( [self.points floatValue] + [pointsToAdd floatValue] )];
}


@end

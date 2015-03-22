//
//  OBAUser.h
//  org.onebusaway.iphone
//
//  Created by Pho Diep on 3/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBAUser : NSObject

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSNumber *points;

-(void)addUserPoints:(NSNumber*)pointsToAdd;

@end
